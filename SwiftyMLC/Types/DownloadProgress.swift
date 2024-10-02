import Foundation

struct DownloadProgress {
    let downloaded: Int
    let total: Int
    let progress: Double
    let localized: String

    init(downloaded: Int = 0, total: Int) {
        self.downloaded = downloaded
        self.total = total
        self.progress = Double(downloaded) / Double(total)
        self.localized = "\(progress * 100)%"
    }
}
