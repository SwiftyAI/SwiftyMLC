import Foundation
import Tagged
import SwiftUI

extension EnvironmentValues {
    @Entry var appConfig: MLCAppConfig = MLCAppConfig(modelList: [])
}

struct MLCAppConfig: Decodable {
    struct Model: Decodable, Identifiable, Hashable {

        static let mock: Self = .init(
            modelId: "Llama 3.2 1B",
            modelLib: "Library",
            modelUrl: "htttps://google.com",
            estimatedVramBytes: 30000000,
            name: "Llama 3.2 1B",
            bytes: 3000000,
            group: "Llama 3.2"
        )

        typealias ModelId = Tagged<(Model, modelId: ()), String>
        typealias Lib = Tagged<(Model, lib: ()), String>
        typealias ModelUrl = Tagged<(Model, modelUrl: ()), URL>

        var id: ModelId { modelId }
        let modelId: ModelId
        let modelLib: Lib
        /// The repository URL
        let modelUrl: ModelUrl
        let estimatedVramBytes: Int
        let name: String
        let bytes: Int64
        let group: String

        /// Local directory where all the model details are stored.
        var localDirectory: URL { Constants.modelsDirectory.appending(path: modelId.rawValue)}
        var localDirectoryMlcChatConfig: URL { localDirectory.appending(path: Constants.fileNameMlcChatConfig) }
        var localDirectoryNdarrayCache: URL { localDirectory.appending(path: Constants.fileNameNdArrayCache)}
        /// Retrieved from: https://huggingface.co/mlc-ai/Llama-3.2-1B-Instruct-q4f16_1-MLC/blob/d09d47e97caae5c79a01fc4889ec3b46ea551fd4/mlc-chat-config.json#L41
        /// Example: https://huggingface.co/mlc-ai/Llama-3.2-1B-Instruct-q4f16_1-MLC/blob/main/tokenizer.json
        func localDirectory(tokenizerFile: MlcChatConfig.TokenizerFile) -> URL { localDirectory.appending(path: tokenizerFile.rawValue) }
        /// Retrieved from: https://huggingface.co/mlc-ai/Llama-3.2-1B-Instruct-q4f16_1-MLC/blob/d09d47e97caae5c79a01fc4889ec3b46ea551fd4/ndarray-cache.json#L7
        /// Example: https://huggingface.co/mlc-ai/Llama-3.2-1B-Instruct-q4f16_1-MLC/blob/main/params_shard_0.bin
        func localDirectory(ndarrayCacheRecord: NdarrayCache.Record) -> URL { localDirectory.appending(path: ndarrayCacheRecord.dataPath) }
        var localDirectoryTemporaryDownloadLocation: URL {
            Constants.temporaryDirectory
                .appending(path: modelId.rawValue)
        }
        /// Temporary download location for an `NdarrayCache.Record`
        func localDirectoryTemporaryDownloadLocation(nsarrayCacheRecord: NdarrayCache.Record) -> URL {
            localDirectoryTemporaryDownloadLocation
                .appending(path: nsarrayCacheRecord.dataPath)
        }
        var localDirectoryFinishedFile: URL { localDirectory.appending(path: "finished.txt") }

        /// Contains config and other files
        var repositoryFilesUrl: URL { modelUrl.rawValue.appending(path: "resolve").appending(path: "main")}
        var repositoryFileMlcChatConfigUrl: URL { repositoryFilesUrl.appending(path: Constants.fileNameMlcChatConfig) }
        var repositoryFileNdarrayCacheUrl: URL { repositoryFilesUrl.appending(path: Constants.fileNameNdArrayCache) }
        /// Retrieved from: https://huggingface.co/mlc-ai/Llama-3.2-1B-Instruct-q4f16_1-MLC/blob/d09d47e97caae5c79a01fc4889ec3b46ea551fd4/mlc-chat-config.json#L41
        /// Example: https://huggingface.co/mlc-ai/Llama-3.2-1B-Instruct-q4f16_1-MLC/blob/main/tokenizer.json
        func repositoryFile(tokenizerFile: MlcChatConfig.TokenizerFile) -> URL { repositoryFilesUrl.appending(path: tokenizerFile.rawValue) }
        /// Retrieved from: https://huggingface.co/mlc-ai/Llama-3.2-1B-Instruct-q4f16_1-MLC/blob/d09d47e97caae5c79a01fc4889ec3b46ea551fd4/ndarray-cache.json#L7
        /// Example: https://huggingface.co/mlc-ai/Llama-3.2-1B-Instruct-q4f16_1-MLC/blob/main/params_shard_0.bin
        func repositoryFile(ndarrayCacheRecord: NdarrayCache.Record) -> URL { repositoryFilesUrl.appending(path: ndarrayCacheRecord.dataPath) }
    }

    let modelList: [Model]
}

struct MLCAppConfigManager {

    func retrieve() throws -> MLCAppConfig {
        guard let file = Bundle.main.url(forResource: "bundle/mlc-app-config", withExtension: "json") else {
            throw AppError("Could not find mlc-app-config.json")
        }
        let data = try Data(contentsOf: file)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let config = try decoder.decode(MLCAppConfig.self, from: data)
        return config
    }
}
