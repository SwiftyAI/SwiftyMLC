import SwiftUI

extension ModelsScreen {

    struct ModelSection: Identifiable {
        var id: String { name }
        let name: String
        var models: [MLCAppConfig.Model]
    }

    @propertyWrapper
    struct Model: DynamicProperty {
        var wrappedValue: Self { self }

        @Binding var selectedModel: MLCAppConfig.Model?
        @Environment(\.dismiss) private var dismiss
        @Environment(\.appConfig) private var appConfig
        @State var areModelsDownloading: Bool = false

        var sections: [ModelSection] {
            var sections: [ModelSection] = []
            for model in appConfig.modelList {
                let index = sections.firstIndex(where: { $0.name == model.group })
                if let index {
                    sections[index].models.append(model)
                } else {
                    sections.append(
                        ModelSection(
                            name: model.group,
                            models: [model]
                        )
                    )
                }
            }
            return sections
        }

        func onAppear() {
            UIApplication.shared.isIdleTimerDisabled = true
        }

        func onDisappear() {
            UIApplication.shared.isIdleTimerDisabled = false
        }

        /// old can be nil because nothing has been selected.
        /// new can be nil because a model could be removed.
        func onChangeSelectedModel(old: MLCAppConfig.Model?, new: MLCAppConfig.Model?) {
            // If there is a new model selected (not removed), and it doesn't match the old one, we dismiss
            if let new, new != old {
                dismiss()
            }
        }
    }
}

struct ModelsScreen: View {

    @Model var model: Model

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.sections) { section in
                    Section(section.name) {
                        ForEach(section.models) { model in
                            ModelRowView(model: model, selectedModel: self.model.$selectedModel)
                        }
                    }
                    .textCase(nil)
                }
            }
            .onChange(of: model.selectedModel, model.onChangeSelectedModel)
            .areModelsDownloading(model.$areModelsDownloading)
            .navigationTitle("Models")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                VStack {
                    if model.areModelsDownloading {
                        DownloadingPopup()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        EmptyView()
                    }
                }.animation(.spring, value: model.areModelsDownloading)
            }

        }
        .interactiveDismissDisabled(model.areModelsDownloading)
        .onAppear(perform: model.onAppear)
        .onDisappear(perform: model.onDisappear)
    }
}

private struct ModelRowView: View {

    private let model: MLCAppConfig.Model
    private let selectedModel: Binding<MLCAppConfig.Model?>
    private let formatterCompleted = ByteCountFormatter.makeForCompleted()
    private let formatterTotal = ByteCountFormatter.makeForTotal()
    @StateObject private var downloadManager: DownloadManager
    @State private var isCancellationShown: Bool = false
    private var phase: DownloadButton.Phase {
        switch downloadManager.phase {
        case .notStarted:
            return .notDownloaded
        case .creatingLocalDirectory,
                .downloadingChatConfig,
                .downloadingArrayCache,
                .downloadingTokenizerFiles,
                .deletingTemporaryFiles:
            return .preparing
        case .downloadingNdArrayCacheRecords(let downloadProgress):
            return .downloading(progress: downloadProgress.progress)
        case .error:
            return .notDownloaded
        case .finished:
            return .downloaded
        }
    }

    private func onTap() {
        Task {
            switch phase {
            case .notDownloaded:
                downloadManager.start()
            case .preparing:
                isCancellationShown = true
            case .downloading:
                isCancellationShown = true
            case .downloaded:
                selectedModel.wrappedValue = model
            }
        }
    }

    private func onRemove() {
        downloadManager.delete()
        // If user removed selectedModel, we need to unmark it.
        if selectedModel.wrappedValue == model {
            selectedModel.wrappedValue = nil
        }
    }

    init(model: MLCAppConfig.Model, selectedModel: Binding<MLCAppConfig.Model?>) {
        self.model = model
        self.selectedModel = selectedModel
        self._downloadManager = .init(
            wrappedValue: DownloadManager(
                model: model
            )
        )
    }

    var body: some View {
        Button {
            onTap()
        } label: {
            LabeledContent {
                if selectedModel.wrappedValue == model {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                } else {
                    // TODO: Add a check
                    DownloadButton(phase: phase, onTap: onTap)
                }
            } label: {
                Group {
                    Text(model.name)
                    subtitle
                        .monospacedDigit()
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .alert(
            "Are you sure you wish to cancel?",
            isPresented: $isCancellationShown,
            actions: {
                Button("Resume", role: .cancel) {}
                Button("Cancel", role: .destructive) {
                    downloadManager.cancel()
                }
            },
            message: {
                Text("\(model.name) will be cancelled.")
            }
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if phase == .downloaded {
                Button("Remove", action: onRemove)
            }
        }
        .model(model, isDownloading: phase.isActive)
    }

    @ViewBuilder
    private var subtitle: some View {
        switch phase {
        case .notDownloaded:
            Text(formatterTotal.string(fromByteCount: model.bytes))
        case .downloaded:
            Text("\(Image(systemName: "iphone")) \(formatterTotal.string(fromByteCount: model.bytes))")
        case .preparing:
            Text("Preparing...")
        case .downloading(let progress):
            let completed = Double(model.bytes) * progress
            let completedString = formatterCompleted.string(fromByteCount: Int64(completed))
            let totalString = formatterTotal.string(fromByteCount: model.bytes)
            Text("\(completedString) / \(totalString)")
        }
    }
}

