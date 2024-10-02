import SwiftUI
import MarkdownUI

struct ChatMessageView: View {

    let chatMessage: ChatMessage

    var body: some View {
        HStack {
            leadingSpacing
            VStack {
                Markdown(chatMessage.text)
                if chatMessage.isLimitReached {
                    Text("Limit Reached")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(backgroundColor)
                .cornerRadiusChat
                .frame(maxWidth: .infinity, alignment: alignment)
            trailingSpacing
        }
    }

    private var backgroundColor: Color {
        switch chatMessage.role {
        case .assistant:
            Color.Chat.assistant
        case .user:
            Color.Chat.user
        }
    }

    private var alignment: Alignment {
        switch chatMessage.role {
        case .assistant:
                .leading
        case .user:
                .trailing
        }
    }

    @ViewBuilder
    private var leadingSpacing: some View {
        switch chatMessage.role {
        case .assistant:
            EmptyView()
        case .user:
            spacer
        }
    }

    @ViewBuilder
    private var trailingSpacing: some View {
        switch chatMessage.role {
        case .assistant:
            spacer
        case .user:
            EmptyView()
        }
    }

    private var spacer: some View {
        Spacer(minLength: 40)
    }
}
