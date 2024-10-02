import SwiftUI

extension ChatScrollView {
    @propertyWrapper
    struct ViewModel: DynamicProperty {
        var wrappedValue: Self { self }

        static let mock: ViewModel = .init(
            chatMessages: .mock
        )

        // MARK: - Public

        let chatMessages: [ChatMessage]

        func scrollToBottom(_ proxy: ScrollViewProxy) {
            if let last = chatMessages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

struct ChatScrollView: View {

    @ViewModel var viewModel: ChatScrollView.ViewModel

    @ViewBuilder
    private var content: some View {
        if viewModel.chatMessages.isEmpty {
            Text("Select a model and type your first message 🎏")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        } else {
            LazyVStack {
                ForEach(viewModel.chatMessages) { chatMessage in
                    ChatMessageView(chatMessage: chatMessage)
                }
            }
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                content
                    .padding()
            }
            .scrollDismissesKeyboard(.interactively) // Does not interactively move text field, an alternative solution: https://github.com/frogcjn/BottomInputBarSwiftUI
            .background(Color.Chat.background)
            .onChange(of: viewModel.chatMessages) {
                viewModel.scrollToBottom(proxy)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.keyboardDidShowNotification)) { _ in
                viewModel.scrollToBottom(proxy)
            }
        }
    }
}

struct ChatScrollView_Preview: PreviewProvider {
    static var previews: some View {
        ChatScrollView(
            viewModel: .init(
                chatMessages: .mock
            )
        )
    }
}
