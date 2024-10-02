import SwiftUI

@main
struct SwiftyMLCApp: App {
    var body: some Scene {
        WindowGroup {
//            InformationPopup_Preview.previews
//            ModelSelectionButton_Preview.previews
//            ChatScrollView_Preview.previews
//            ChatTextField_Previews.previews
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if
            let config = createConfig(),
            createModelDirectory() {
            ChatScreen()
                .environment(\.appConfig, config)
        } else {
            ContentUnavailableView(
                "Something went wrong",
                systemImage: "exclamationmark.triangle",
                description: Text("Please contact us")
            )
        }
    }

    func createConfig() -> MLCAppConfig? {
        do {
            return try MLCAppConfigManager().retrieve()
        } catch {
            // TODO: Log non fatal
            return nil
        }
    }

    func createModelDirectory() -> Bool {
        do {
//            try FileManager.default.removeItem(at: Constants.modelsDirectory)
            try FileManager.default.createDirectory(at: Constants.modelsDirectory, withIntermediateDirectories: true)

            let fileURLs = try FileManager.default.contentsOfDirectory(at: Constants.modelsDirectory, includingPropertiesForKeys: nil)
            for file in fileURLs {
                print(file)
            }

            return true
        } catch {
            // TODO: Log non fatal
            return false
        }
    }
}
