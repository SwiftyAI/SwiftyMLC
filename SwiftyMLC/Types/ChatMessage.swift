import Foundation

struct ChatMessage: Identifiable, Equatable {
    enum Role: Equatable {
        case assistant
        case user
    }

    let id: UUID = UUID()
    let role: Role
    var text: String
    var isLimitReached: Bool
    // TODO: Maybe image attachments in the future
}

extension ChatMessage {
    init(role: Role, text: String) {
        self.role = role
        self.text = text
        self.isLimitReached = false
    }
}

extension ChatMessage {
    static let mockAssistant: Self = .init(
        role: .assistant,
        text: "Hello how can I help you today?"
    )
    static let mockUser: Self = .init(
        role: .user,
        text: "You can help me by telling me my name."
    )
}

extension [ChatMessage] {
    static let mock: Self = [
        .init(
            role: .assistant,
            text: "Hello how can I help you today?"
        ),
        .init(
            role: .user,
            text: "Hello I need help with a few things."
        ),
        .init(
            role: .assistant,
            text: "No worries, I'm going to ask you a number of questions and I want you to answer them very truthfully. If you don't there will be consequences.",
            isLimitReached: true
        ),
        .init(
            role: .user,
            text: "I don't think I like the sound of that, that sounds menacing and I don't want to be a part of that. Especially because it means that there is danger on my life."
        ),
    ]
}
