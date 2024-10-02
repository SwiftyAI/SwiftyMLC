import SwiftUI

extension ChatScreen {
    @propertyWrapper
    struct Model: DynamicProperty {
        var wrappedValue: Self { self }

        @State var model: MLCAppConfig.Model?
        @Environment(\.appConfig) private var appConfig
        @AppStorage("modelId") private var persistedModelId: MLCAppConfig.Model.ModelId?
        @State private(set) var chatMessages: [ChatMessage] = .init()
        @StateObject private var chatManager = ChatManager()
        var chatManagerPhase: ChatManager.Phase { chatManager.phase }
        var chatTextFieldPhase: ChatTextField.Phase {
            switch chatManager.phase {
            case .loading:
                    .disabled(reason: "Loading...")
            case .ready:
                    .enabled
            case .unloading:
                    .disabled(reason: "Unloading...")
            case .unloaded:
                    .disabled(reason: "Select a model")
            case .generating:
                    .disabled(reason: "Generating...")
            }
        }

        func onSubmit(_ text: String) {
            chatMessages.append(
                .init(
                    role: .user,
                    text: text
                )
            )
            chatManager.complete(chatMessages) { update in
                switch update {
                case .delta(let delta):
                    guard let lastChatMessage = chatMessages.last else {
                        return AppLogger.critical(category: .chatView, "Last message should always exist (at least be role: user)")
                    }
                    switch lastChatMessage.role {
                    case .assistant:
                        chatMessages[chatMessages.count - 1].text.append(delta)
                    case .user:
                        chatMessages.append(ChatMessage(role: .assistant, text: delta))
                    }
                case .lengthReached:
                    chatMessages[chatMessages.count - 1].isLimitReached = true
                case .unknown:
                    break
                }
            }
        }

        func onChangeModel(old: MLCAppConfig.Model?, new: MLCAppConfig.Model?) {

            if persistedModelId != new?.modelId {
                persistedModelId = new?.modelId
            }

            /// If model deleted, unload it
            guard let new else {
                // If there was an old one
                if let old {
                    chatManager.unload(old)
                }
                return
            }

            /// If there isn't an old, then immediately load the new one (nothing to compare)
            guard let old else {
                return loadModel(new)
            }

            /// Load the new model if it's not the same as old
            if old != new {
                loadModel(new)
            }
        }

        func onFirstAppear() {
            guard let modelId = persistedModelId else {
                return
            }

            guard let model = appConfig.modelList.first(where: { $0.modelId == modelId }) else {
                AppLogger.critical("Could not find model with id: \(modelId)")
                return
            }

            self.model = model
        }

        private func loadModel(_ model: MLCAppConfig.Model) {
            chatManager.load(model)
        }
    }
}

struct ChatScreen: View {
    
    @Model private var viewModel: Model

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ChatScrollView(
                    viewModel: .init(
                        chatMessages: viewModel.chatMessages
                    )
                )
                ChatTextField(
                    viewModel: .init(
                        phase: viewModel.chatTextFieldPhase,
                        onSubmit: viewModel.onSubmit
                    )
                )
            }
            .safeAreaInset(edge: .top) {
                ModelSelectionButton(
                    model: viewModel.$model,
                    chatManagerPhase: viewModel.chatManagerPhase
                )
            }
        }
        .onChange(of: viewModel.model, viewModel.onChangeModel)
        .onFirstAppear(viewModel.onFirstAppear)
    }
}
