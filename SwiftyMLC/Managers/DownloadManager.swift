import SwiftUI

@MainActor
class DownloadManager: ObservableObject {

    enum Phase {
        // IDEA: Have a total progress fraction, multiply that by the bytes?
        case notStarted
        case error

        case creatingLocalDirectory
        case downloadingChatConfig
        case downloadingArrayCache
        case downloadingTokenizerFiles(DownloadProgress)
        case downloadingNdArrayCacheRecords(DownloadProgress)
        case deletingTemporaryFiles
        case finished

        var localizedDescription: String {
            switch self {
            case .notStarted: return "Not started"
            case .creatingLocalDirectory: return "Creating local Directory"
            case .downloadingChatConfig: return "Downloading chat Config"
            case .downloadingArrayCache: return "Downloading array Cache"
            case .downloadingTokenizerFiles(let progress): return "Downloading tokenizer files (\(progress.localized))"
            case .downloadingNdArrayCacheRecords(let progress): return "Downloading array cache records (\(progress.localized))"
            case .deletingTemporaryFiles: return "Deleting temporary files"
            case .error: return "Error"
            case .finished: return "Finished"
            }
        }
    }

    private let fileManager: FileManager = .default

    private let model: MLCAppConfig.Model
    @Published var phase: Phase = .notStarted
    private var task: Task<Void, Never>?

    init(model: MLCAppConfig.Model) {
        self.model = model
        refreshPhase()
    }

    func start() {
        task = Task { @MainActor in
            do {
                AppLogger.info(category: .downloadManager(model))
                try createModelFolderIfNeeded()
                let mlcChatConfig = try await downloadMlcChatConfig()
                let ndarrayCache = try await downloadNdarrayCache()
                try await downloadTokenizerFiles(from: mlcChatConfig)
                try await downloadNdArrayCacheRecords(from: ndarrayCache)
                try deleteLocalDirectoryTemporaryDownloadLocation()
                try markFinished()

            } catch is CancellationError {
                AppLogger.info(category: .downloadManager(model))
                phase = .notStarted
            } catch URLError.cancelled {
                AppLogger.info(category: .downloadManager(model))
                phase = .notStarted
            } catch {
                AppLogger.error(category: .downloadManager(model), error.localizedDescription)
                phase = .error
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    /// Removes model data and temporary files
    func delete() {
        do {
            let localDirectory = model.localDirectory
            if fileManager.fileExists(atPath: localDirectory.path()) {
                AppLogger.info(category: .downloadManager(model), "Will remove \(localDirectory)")
                try fileManager.removeItem(at: localDirectory)
            }
            let localDirectoryTemporaryDownloadLocation = model.localDirectoryTemporaryDownloadLocation
            if fileManager.fileExists(atPath: localDirectoryTemporaryDownloadLocation.path()) {
                AppLogger.info(category: .downloadManager(model), "Will remove \(localDirectoryTemporaryDownloadLocation)")
                try fileManager.removeItem(at: localDirectoryTemporaryDownloadLocation)
            }
        } catch {
            AppLogger.error(category: .downloadManager(model), error.localizedDescription)
        }
        refreshPhase()
    }

    private func createModelFolderIfNeeded() throws {
        AppLogger.info(category: .downloadManager(model))
        try Task.checkCancellation()
        phase = .creatingLocalDirectory

        let localDirectory = model.localDirectory

        if fileManager.fileExists(atPath: localDirectory.path()) == false {
            try fileManager.createDirectory(at: localDirectory, withIntermediateDirectories: false)
        }
    }

    private func downloadMlcChatConfig() async throws -> MlcChatConfig {
        AppLogger.info(category: .downloadManager(model))
        try Task.checkCancellation()

        phase = .downloadingChatConfig

        let localDirectoryMlcChatConfig = model.localDirectoryMlcChatConfig

        if fileManager.fileExists(atPath: localDirectoryMlcChatConfig.path()) == false {
            let data = try await URLSession.shared.data(from: model.repositoryFileMlcChatConfigUrl).0

            try Task.checkCancellation()

            let mlcChatConfig = try JSONDecoder.makeFromSnakeCase().decode(MlcChatConfig.self, from: data)
            try data.write(to: localDirectoryMlcChatConfig)
            return mlcChatConfig
        } else {
            let data = try Data(contentsOf: localDirectoryMlcChatConfig)
            let mlcChatConfig = try JSONDecoder.makeFromSnakeCase().decode(MlcChatConfig.self, from: data)
            return mlcChatConfig
        }
    }

    private func downloadNdarrayCache() async throws -> NdarrayCache {
        AppLogger.info(category: .downloadManager(model))
        try Task.checkCancellation()
        phase = .downloadingArrayCache

        let localDirectoryNdArrayCache = model.localDirectoryNdarrayCache

        if fileManager.fileExists(atPath: localDirectoryNdArrayCache.path()) == false {
            let data = try await URLSession.shared.data(from: model.repositoryFileNdarrayCacheUrl).0
            try Task.checkCancellation()
            /// Ensures it's a valid file before saving
            let ndarrayCache = try JSONDecoder().decode(NdarrayCache.self, from: data)
            try data.write(to: localDirectoryNdArrayCache)
            return ndarrayCache
        } else {
            let data = try Data(contentsOf: localDirectoryNdArrayCache)
            let ndarrayCache = try JSONDecoder().decode(NdarrayCache.self, from: data)
            return ndarrayCache
        }
    }

    private func downloadTokenizerFiles(from mlcChatConfig: MlcChatConfig) async throws {
        AppLogger.info(category: .downloadManager(model))
        try Task.checkCancellation()
        let total = mlcChatConfig.tokenizerFiles.count
        phase = .downloadingTokenizerFiles(.init(total: total))

        for (index, tokenizerFile) in mlcChatConfig.tokenizerFiles.enumerated() {
            let localDirectoryTokenizerFile = model.localDirectory(tokenizerFile: tokenizerFile)
            phase = .downloadingTokenizerFiles(.init(downloaded: index, total: total))

            if fileManager.fileExists(atPath: localDirectoryTokenizerFile.path()) == false {
                let repositoryFileTokenizerFileUrl = model.repositoryFile(tokenizerFile: tokenizerFile)
                let data = try await URLSession.shared.data(from: repositoryFileTokenizerFileUrl).0
                try Task.checkCancellation()
                try data.write(to: localDirectoryTokenizerFile)
            }
        }
    }

    private func downloadNdArrayCacheRecords(from ndarrayCache: NdarrayCache) async throws {
        AppLogger.info(category: .downloadManager(model))
        try Task.checkCancellation()
        let total = ndarrayCache.records.count
        phase = .downloadingNdArrayCacheRecords(.init(total: total))

        for (index, record) in ndarrayCache.records.enumerated() {
            let localDirectoryNdArrayCacheRecord = model.localDirectory(ndarrayCacheRecord: record)
            phase = .downloadingNdArrayCacheRecords(.init(downloaded: index, total: total))
            
            if fileManager.fileExists(atPath: localDirectoryNdArrayCacheRecord.path()) == false {
                let repositoryFileNdArrayCacheRecordUrl = model.repositoryFile(ndarrayCacheRecord: record)
                let localDirectoryTemporaryDownloadLocationRecord = model.localDirectoryTemporaryDownloadLocation(nsarrayCacheRecord: record)

                let tempUrl = try await URLSession.shared.download(
                    from: repositoryFileNdArrayCacheRecordUrl,
                    temporaryUrl: localDirectoryTemporaryDownloadLocationRecord,
                    onProgress: { [weak self] downloadProgress in
                    Task { @MainActor in
                        // Calculates a percentage based on a file in progress and the total number of files to be completed
                        let multiplier = Int(100)
                        let totalMultiplied = total * multiplier
                        let downloadedMultiplied = (index * multiplier) + Int((Double(multiplier) * downloadProgress.progress))
                        let progress = DownloadProgress(downloaded: downloadedMultiplied, total: totalMultiplied)
                        self?.phase = .downloadingNdArrayCacheRecords(progress)
                    }
                }).0

                try Task.checkCancellation()
                try fileManager.moveItem(at: tempUrl, to: localDirectoryNdArrayCacheRecord)
            }
        }
    }

    /// Should not throw an error as the location should still exist after downloading NdarrachCache records
    private func deleteLocalDirectoryTemporaryDownloadLocation() throws {
        phase = .deletingTemporaryFiles
        try fileManager.removeItem(at: model.localDirectoryTemporaryDownloadLocation)
    }

    /// Adds a file indicating finished
    private func markFinished() throws {
        AppLogger.info(category: .downloadManager(model))
        if fileManager.createFile(atPath: model.localDirectoryFinishedFile.path(), contents: nil) == false {
            throw AppError("Could not create finished file.")
        }
        phase = .finished
    }

    private func isFinished() -> Bool {
        fileManager.fileExists(atPath: model.localDirectoryFinishedFile.path())
    }

    /// Check if model is finished
    private func refreshPhase() {
        phase = isFinished() ? .finished : .notStarted
    }
}
