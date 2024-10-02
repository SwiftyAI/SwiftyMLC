import SwiftUI

/// Allows user to use return key to insert new lines.
private class TextFieldDelegate: NSObject, UITextFieldDelegate {

    static let shared = TextFieldDelegate()

    private override init() {}

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        false
    }
}

extension TextField {
    func enableNewLineOnReturnKey() -> some View {
        introspect(.textField, on: .iOS(.v18)) { textField in
            textField.delegate = TextFieldDelegate.shared
        }
    }
}
