import Foundation

extension URL: @retroactive ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = .init(string: value)!
    }
}
