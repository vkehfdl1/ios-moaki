import SwiftUI

struct PracticeInputField: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        TextField("여기에 입력하세요", text: $text)
            .font(.system(size: 22, design: .monospaced))
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused($isFocused)
    }
}
