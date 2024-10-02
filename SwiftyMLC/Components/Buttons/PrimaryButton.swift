import SwiftUI

struct PrimaryButton: View {

    enum Style {
        case primary
        case secondary
    }

    let title: String
    let style: Style
    let action: () -> ()

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .bold()
        }
        .apply(style)
        .controlSize(.large)
        .buttonBorderShape(.capsule)
    }
}

private extension View {
    @ViewBuilder
    func apply(_ style: PrimaryButton.Style) -> some View {
        switch style {
        case .primary:
            buttonStyle(.borderedProminent)
        case .secondary:
            buttonStyle(.bordered)
        }
    }
}

#Preview {
    VStack {
        PrimaryButton(title: "Primary", style: .primary, action: {})
        PrimaryButton(title: "Secondary", style: .secondary, action: {})
    }
}
