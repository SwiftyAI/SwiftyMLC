import SwiftUI

enum IsModelDownloadingPreferenceKey: PreferenceKey {
    typealias Value = [MLCAppConfig.Model.ModelId: Bool]
    static var defaultValue: Value = .init()
    static func reduce(value: inout Value, nextValue: () -> Value) {
        let next = nextValue()
        for (key, newValue) in next {
            value[key] = newValue
        }
    }
}

extension View {
    func model(_ model: MLCAppConfig.Model, isDownloading: Bool) -> some View {
        preference(key: IsModelDownloadingPreferenceKey.self, value: [model.modelId: isDownloading])
    }

    func areModelsDownloading(_ binding: Binding<Bool>) -> some View {
        onPreferenceChange(IsModelDownloadingPreferenceKey.self) { value in
            let isDownloading = value.contains(where: { (_, value) in
                value
            })
            binding.wrappedValue = isDownloading
        }
    }
}
