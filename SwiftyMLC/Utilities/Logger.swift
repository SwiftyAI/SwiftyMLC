import os
import Foundation

struct AppLogger {
    static func log(
        category: Category = .default,
        level: Level,
        _ message: String?,
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) {
        var string = "🪵 (\(category) - \(level)) - \(file):\(line) - \(function)"
        if let message {
            string.append(" - \(message)")
        }
        switch level {
        case .debug:
            category.logger.debug("\(string)")
        case .info:
            category.logger.info("\(string)")
        case .notice:
            category.logger.notice("\(string)")
        case .error:
            category.logger.error("\(string)")
        case .critical:
            category.logger.critical("\(string)")
        }

        if ProcessInfo.processInfo.environment["IS_CI"] == "true" {
            // Necessary to make it appear when running from terminal, for some reason it does appear correctly in console though.
            // Maybe more info: https://stackoverflow.com/questions/46660112/viewing-os-log-messages-in-device-console
            // https://forums.developer.apple.com/forums/thread/705868
            print(string)
        }
    }

    static func info(category: Category = .default, _ message: String? = nil, file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(category: category, level: .info, message, file: file, function: function, line: line)
    }

    static func error(category: Category = .default, _ message: String?, file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(category: category, level: .error, message, file: file, function: function, line: line)
    }

    static func critical(category: Category = .default, _ message: String?, file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(category: category, level: .critical, message, file: file, function: function, line: line)
    }
}

extension AppLogger {

    enum Category: CustomStringConvertible, Hashable {

        private static var loggers: [AppLogger.Category: Logger] = [:]

        case `default`
        case modelListScreen
        case downloadManager(MLCAppConfig.Model)
        case chatManager(MLCAppConfig.Model?)
        case chatView

        var description: String {
            switch self {
            case .default: "default"
            case .modelListScreen: "modelListScreen"
            case .downloadManager(let model): "ModelDownloadManager(\(model.id.rawValue))"
            case .chatManager(let model): "ChatManager(\(model?.id.rawValue ?? "Unknown"))"
            case .chatView: "ChatView"
            }
        }

        var logger: Logger {
            if let logger = Self.loggers[self] {
                return logger
            } else {
                let logger = Logger(subsystem: "App", category: description)
                Self.loggers[self] = logger
                return logger
            }
        }
    }

    enum Level: String, CustomStringConvertible {
        /// In memory only
        case debug
        case info
        case notice
        case error
        case critical

        var description: String {
            let emoji: String = {
                switch self {
                case .debug: return "🔍"
                case .info: return "✅"
                case .notice: return "🪧"
                case .error: return "❌"
                case .critical: return "💥"
                }
            }()
            return "\(emoji) \(rawValue)"
        }
    }
}
