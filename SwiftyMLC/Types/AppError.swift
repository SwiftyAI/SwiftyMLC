import Foundation

struct AppError: LocalizedError {
    /// Programmer facing
    let errorDescription: String?
    /// User facing
    let localizedDescription: String

    init(_ errorDescription: String) {
        self.errorDescription = errorDescription
        self.localizedDescription = "An unknown error occurred."
    }
}
