import SwiftUI

struct DownloadingPopup: View {
    var body: some View {
        HStack {
            LabeledContent {
                ProgressView()
                    .tint(.accentColor)
            } label: {
                Group {
                    Text("Model Downloading")
                        .font(.headline)
                    Text("Keep this screen open until everything has finished.")
                }
            }
        }
        .padding()
        .background(Color.InformationPopup.background)
        .cornerRadiusDefault
        .padding()
    }
}

struct InformationPopup_Preview: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ScrollView {
                Text("Hello")
            }
            .safeAreaInset(edge: .bottom) {
                DownloadingPopup()
            }
        }
    }
}
