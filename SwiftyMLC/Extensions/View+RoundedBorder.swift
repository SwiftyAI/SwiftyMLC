import SwiftUI

extension View {
    func roundedBorder(cornderRadius: CGFloat, color: Color, lineWidth: CGFloat) -> some View {
        cornerRadius(cornderRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornderRadius)
                    .strokeBorder(color, lineWidth: lineWidth)
            )
    }
}
