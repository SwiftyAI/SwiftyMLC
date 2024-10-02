import SwiftUI

extension View {
    @ViewBuilder
    var cornerRadiusChat: some View {
        clipShape(RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    var cornerRadiusDefault: some View {
        clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    var cornerRadiusSmall: some View {
        clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
