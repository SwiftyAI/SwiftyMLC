import Foundation

extension ByteCountFormatter {
    static func makeForTotal() -> ByteCountFormatter {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB]
        formatter.zeroPadsFractionDigits = true
        formatter.allowsNonnumericFormatting = false
        return formatter
    }

    static func makeForCompleted() -> ByteCountFormatter {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.zeroPadsFractionDigits = true
        formatter.allowsNonnumericFormatting = false
        return formatter
    }
}
