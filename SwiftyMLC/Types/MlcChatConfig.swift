import Foundation
import Tagged

struct MlcChatConfig: Decodable {
    typealias TokenizerFile = Tagged<MlcChatConfig, String>

    let tokenizerFiles: [TokenizerFile]
}
