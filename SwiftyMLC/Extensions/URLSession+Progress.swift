import Foundation

/// https://stackoverflow.com/a/70396188/4698501
extension URLSession {
    func download(from url: URL, temporaryUrl: URL, delegate: URLSessionTaskDelegate? = nil, onProgress: (DownloadProgress) -> ()) async throws -> (URL, URLResponse) {
        let bufferSize = 65_536
        let estimatedSize: Int = 1_000_000

        let (asyncBytes, response) = try await bytes(for: URLRequest(url: url), delegate: delegate)
        let expectedLength = response.expectedContentLength                             // note, if server cannot provide expectedContentLength, this will be -1
        let total = expectedLength > 0 ? Int(expectedLength) : estimatedSize

        /// Remove the temporary file if it exists. Can happen if a download is interupted.
        /// We want a temporary location so we don't keep creating temporary files.
        if FileManager.default.fileExists(atPath: temporaryUrl.path()) {
            try FileManager.default.removeItem(at: temporaryUrl)
        }

        /// Create the intermediate directory if necessary
        let temporaryUrlDirectory = temporaryUrl.deletingLastPathComponent()
        if FileManager.default.fileExists(atPath: temporaryUrlDirectory.path()) == false {
            try FileManager.default.createDirectory(at: temporaryUrlDirectory, withIntermediateDirectories: true, attributes: nil)
        }

        guard let output = OutputStream(url: temporaryUrl, append: false) else {
            throw URLError(.cannotOpenFile)
        }
        output.open()

        var buffer = Data()
        if expectedLength > 0 {
            buffer.reserveCapacity(min(bufferSize, Int(expectedLength)))
        } else {
            buffer.reserveCapacity(bufferSize)
        }

        var count: Int = 0
        for try await byte in asyncBytes {
            try Task.checkCancellation()

            count += 1
            buffer.append(byte)

            if buffer.count >= bufferSize {
                try output.write(buffer)
                buffer.removeAll(keepingCapacity: true)

                if expectedLength < 0 || count > expectedLength {
                    onProgress(DownloadProgress(downloaded: count, total: count + estimatedSize))
                } else {
                    onProgress(DownloadProgress(downloaded: count, total: total))
                }
            }
        }

        if !buffer.isEmpty {
            try output.write(buffer)
        }

        output.close()

        onProgress(DownloadProgress(downloaded: count, total: count))

        return (temporaryUrl, response)
    }
}

extension OutputStream {
    func write(_ data: Data) throws {
        try data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) throws in
            guard var pointer = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw AppError("OutputStreamError.bufferFailure")
            }

            var bytesRemaining = buffer.count

            while bytesRemaining > 0 {
                let bytesWritten = write(pointer, maxLength: bytesRemaining)
                if bytesWritten < 0 {
                    throw AppError("OutputStreamError.writeFailure")
                }

                bytesRemaining -= bytesWritten
                pointer += bytesWritten
            }
        }
    }
}
