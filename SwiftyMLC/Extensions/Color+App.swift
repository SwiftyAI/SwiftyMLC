import SwiftUI

extension Color {
    static var contentBackground: Color {
        Color(uiColor: .systemGroupedBackground)
    }

    static var contentForeground: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }

    enum InformationPopup {
        static let background = Color(
            _light: Color.contentForeground.mix(with: Color.accentColor, by: 0.1),
            _dark: Color.contentForeground.mix(with: Color.accentColor, by: 0.1)
        )
    }

    enum Chat {
        static let background: Color = Color(
            _light: Color(uiColor: .secondarySystemGroupedBackground),
            _dark: Color(uiColor: .systemGroupedBackground)
        )

        static let assistant: Color = Color(
            _light: Color(uiColor: .systemGroupedBackground),
            _dark: Color(uiColor: .secondarySystemGroupedBackground)
        )

        static let user: Color = Color(
            _light: Color.accentColor,
            _dark: Color.accentColor.mix(with: .black, by: 0.4)
        )

        static let input: Color = assistant
        static let inputBorder: Color = .accentColor
    }
}

// https://www.jessesquires.com/blog/2023/07/11/creating-dynamic-colors-in-swiftui/

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

private extension Color {
    init(_light light: Color, _dark dark: Color) {
        #if canImport(UIKit)
        self.init(_light: UIColor(light), _dark: UIColor(dark))
        #else
        self.init(_light: NSColor(light), _dark: NSColor(dark))
        #endif
    }

    #if canImport(UIKit)
    init(_light light: UIColor, _dark dark: UIColor) {
        #if os(watchOS)
        // watchOS does not support light mode / dark mode
        // Per Apple HIG, prefer dark-style interfaces
        self.init(uiColor: dark)
        #else
        self.init(uiColor: UIColor(dynamicProvider: { traits in
            switch traits.userInterfaceStyle {
            case .light, .unspecified:
                return light

            case .dark:
                return dark

            @unknown default:
                assertionFailure("Unknown userInterfaceStyle: \(traits.userInterfaceStyle)")
                return light
            }
        }))
        #endif
    }
    #endif

    #if canImport(AppKit)
    init(_light: NSColor, _dark: NSColor) {
        self.init(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            switch appearance.name {
            case .aqua,
                 .vibrantLight,
                 .accessibilityHighContrastAqua,
                 .accessibilityHighContrastVibrantLight:
                return light

            case .darkAqua,
                 .vibrantDark,
                 .accessibilityHighContrastDarkAqua,
                 .accessibilityHighContrastVibrantDark:
                return dark

            default:
                assertionFailure("Unknown appearance: \(appearance.name)")
                return light
            }
        }))
    }
    #endif
}

