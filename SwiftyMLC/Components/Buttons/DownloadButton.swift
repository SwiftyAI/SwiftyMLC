import SwiftUI

struct DownloadButton: View {
    enum Phase: Equatable {
        case notDownloaded
        /// Any initial setup before downloading
        case preparing
        /// Progress out of 1
        case downloading(progress: Double)
        // Button is hidden
        case downloaded

        /// `true` if preparing or downloading.
        var isActive: Bool {
            switch self {
            case .notDownloaded:
                false
            case .preparing:
                true
            case .downloading:
                true
            case .downloaded:
                false
            }
        }
    }

    let phase: Phase
    let onTap: () -> ()

    var body: some View {
        Button {
            onTap()
        } label: {
            label
        }
        .buttonStyle(.plain) // Important: https://old.reddit.com/r/SwiftUI/comments/11v492t/can_someone_explain_you_can_combine_a_list_with_a/jcrgl2i/
    }

    @ViewBuilder
    private var label: some View {
        switch phase {
        case .notDownloaded:
            Image(systemName: "icloud.and.arrow.down")
                .foregroundStyle(Color.accentColor)
        case .preparing:
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.accentColor)
        case .downloading(let progress):
            ProgressView(value: progress, total: 1)
                .progressViewStyle(.circular)
                .tint(.accentColor)
        case .downloaded:
            EmptyView()
        }
    }
}

#Preview {
    Form {
        DownloadButton(phase: .notDownloaded, onTap: {})
        DownloadButton(phase: .downloading(progress: 0.5), onTap: {})
        DownloadButton(phase: .downloaded, onTap: {})

    }
}
