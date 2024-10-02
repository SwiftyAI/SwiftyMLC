import SwiftUI

struct ModelSelectionButton: View {

    @Binding var model: MLCAppConfig.Model?
    let chatManagerPhase: ChatManager.Phase
    @State private var isSheetShown: Bool = false

    private var isDisabled: Bool {
        switch chatManagerPhase {
        case .loading, .unloading, .generating:
            true
        case .unloaded, .ready:
            false
        }
    }

    private var title: String {
        switch chatManagerPhase {
        case .loading:
            "Model (Loading)"
        case .ready:
            "Model"
        case .unloading:
            "Model (Unloading)"
        case .unloaded:
            "Model"
        case .generating:
            "Model (Generating)"
        }
    }

    private var subtitle: String {
        switch chatManagerPhase {
        case .loading(let model):
            model.name
        case .ready(let model):
            model.name
        case .unloading(let model):
            model.name
        case .unloaded:
            "Select a Model"
        case .generating(let model):
            model.name
        }
    }

    @ViewBuilder
    private var value: some View {
        switch chatManagerPhase {
        case .loading, .unloading, .generating:
            ProgressView()
        case .unloaded, .ready:
            Image(systemName: "rectangle.2.swap")
                .foregroundStyle(.secondary)
        }
    }

    var body: some View {
        Button {
            isSheetShown = true
        } label: {
            LabeledContent {
                value
            } label: {
                Text(title)
                    .font(.headline)
                Text(subtitle)
            }
            .padding()
            .background(Color.Chat.assistant)
            .cornerRadiusDefault
            .padding()
        }
        .disabled(isDisabled)
        .animation(.linear(duration: 0.2), value: chatManagerPhase)
        .buttonStyle(.plain)
        .sheet(isPresented: $isSheetShown) {
            ModelsScreen(model: .init(selectedModel: $model))
        }
    }
}

struct ModelSelectionButton_Preview: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ScrollView {
                Text("Hello")
            }
            .safeAreaInset(edge: .top) {
                ModelSelectionButton(model: .constant(.mock), chatManagerPhase: .ready(MLCAppConfig.Model.mock))
            }
        }
    }
}
