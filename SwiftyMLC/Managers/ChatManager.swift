import SwiftUI
import MLCSwift
import NaturalLanguage

extension String {
    /// A very basic method of getting tokens
    func tokenCount() -> Int {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = self
        return tokenizer.tokens(for: startIndex..<endIndex).count
    }
}

@MainActor
class ChatManager: ObservableObject {

    enum Phase: Equatable {
        case loading(MLCAppConfig.Model)
        case ready(MLCAppConfig.Model)

        case unloading(MLCAppConfig.Model)
        case unloaded

        case generating(MLCAppConfig.Model)
    }

    enum UpdatePhase {
        case delta(String)
        case lengthReached
        case unknown
    }

    private let engine = MLCEngine()

    // MARK: - Public

    @Published private(set) var phase: Phase = .unloaded

    /// Performs the following:
    /// - `engine.unload()`
    /// - `memory check` - TODO: Ensure there is enough VRAM
    /// - `engine.reload`
    /// - single prompt warm up
    func load(_ model: MLCAppConfig.Model) {
        Task { @MainActor in
            phase = .loading(model)

            await engine.unload()
            await engine.reload(
                modelPath: model.localDirectory.path(),
                modelLib: model.modelLib.rawValue
            )
            // run a simple prompt with empty content to warm up system prompt
            // helps to start things before user start typing
            for await _ in await engine.chat.completions.create(
                messages: [ChatCompletionMessage(role: .user, content: "")],
                max_tokens: 1
            ) {}

            phase = .ready(model)
        }
    }

    func unload(_ model: MLCAppConfig.Model) {
        Task { @MainActor in
            phase = .unloading(model)
            await engine.unload()
            phase = .unloaded
        }
    }

    func complete(_ chatMessages: [ChatMessage], isStartDelayed: Bool = true, onUpdate: @escaping (UpdatePhase) -> ()) {
        guard case .ready(let model) = phase else {
            AppLogger.critical(category: .chatManager(nil), "Should not have been possible for user to generate if it wasn't ready.")
            return
        }

        Task {
            await MainActor.run {
                phase = .generating(model)
            }

            /// A delay is needed as otherwise the user message is appended with a noticeable lag as streaming text begins immediately.
            if isStartDelayed {
                try await Task.sleep(for: .milliseconds(300))
            }

            /// Simple method of limiting context window to approx 2048 tokens
            var messages = [ChatCompletionMessage]()
            var totalTokens = 0
            let maxTokens = 2048
            for chatMessage in chatMessages.reversed() {
                let count = chatMessage.text.tokenCount()
                if totalTokens + count < maxTokens {
                    messages = [ChatCompletionMessage(chatMessage: chatMessage)] + messages
                    totalTokens += count
                } else {
                    break
                }
            }

            for await response in await engine.chat.completions.create(
                messages: messages,
                max_tokens: 1024,
                stream_options: StreamOptions(include_usage: true)
            ) {

                guard let choice = response.choices.first else {
                    AppLogger.critical(category: .chatManager(model), "Missing choice. Usage: \(String(describing: response.usage))")
                    await update(phase: .unknown)
                    break
                }

                func update(phase: UpdatePhase) async {
                    await MainActor.run {
                        onUpdate(phase)
                    }
                }

                if let text = choice.delta.content?.asText() {
                    AppLogger.info(category: .chatManager(model), "Got delta: \(text)")
                    await update(phase: .delta(text))
                }

                if let finishReason = choice.finish_reason {
                    AppLogger.info(category: .chatManager(model), "Finished: \(finishReason)")

                    if finishReason == "length" {
                        await update(phase: .lengthReached)
                    } else {
                        await update(phase: .unknown)
                    }
                    break
                }
            }

            await MainActor.run {
                phase = .ready(model)
            }
        }
    }
}

extension ChatCompletionMessage {
    init(chatMessage: ChatMessage) {
        var role: ChatCompletionRole {
            switch chatMessage.role {
            case .user: return .user
            case .assistant: return .assistant
            }
        }
        self.init(role: role, content: chatMessage.text)
    }
}
