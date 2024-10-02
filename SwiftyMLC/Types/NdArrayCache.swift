import Foundation

struct NdarrayCache: Decodable {
    struct Record: Decodable {
        let dataPath: String
    }

    let records: [Record]
}
