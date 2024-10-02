import SwiftUI
import SwiftUIIntrospect

extension ChatTextField {

    enum Phase {
        case disabled(reason: String)
        case enabled
    }

    @propertyWrapper
    struct ViewModel: DynamicProperty {
        static let mock: Self = .init(
            phase: .enabled,
            onSubmit: { _ in }
        )

        var wrappedValue: Self { self }

        // MARK: - Public

        let phase: Phase
        let onSubmit: (String) -> ()

        // MARK: - Private

        @State var text: String = ""
        var placeholder: String {
            switch phase {
            case .disabled(let reason):
                reason
            case .enabled:
                "Enter a message"
            }
        }

        var isTextFieldDisabled: Bool {
            switch phase {
            case .disabled: true
            case .enabled: false
            }
        }

        var isButtonDisabled: Bool {
            switch phase {
            case .disabled: true
            case .enabled: text.isEmpty
            }
        }

        var roundedBorderColor: Color {
            switch phase {
            case .disabled: .clear
            case .enabled: Color.Chat.inputBorder
            }
        }

        func onButtonTap() {
            onSubmit(text)
            text = ""
        }
    }
}

struct ChatTextField: View {

    @ViewModel var viewModel: ViewModel

    var body: some View {
        HStack(alignment: .bottom) {
            TextField(viewModel.placeholder, text: viewModel.$text, axis: .vertical)
                .enableNewLineOnReturnKey()
                .lineLimit(1...9)
                .frame(minHeight: 30)
                Button {
                    viewModel.onButtonTap()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                }
                .disabled(viewModel.isButtonDisabled)
        }
        .padding(
            .init(
                top: 10,
                leading: 24,
                bottom: 10,
                trailing: 10
            )
        )
            .background(Color.Chat.assistant)
            .roundedBorder(cornderRadius: 24, color: viewModel.roundedBorderColor, lineWidth: 1)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.Chat.background)
    }
}

struct ChatTextField_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ChatScrollView(viewModel: .mock)
                ChatTextField(viewModel: .mock)
            }
        }
    }
}


