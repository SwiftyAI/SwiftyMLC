import Foundation

extension JSONDecoder {
    static func makeFromSnakeCase() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
