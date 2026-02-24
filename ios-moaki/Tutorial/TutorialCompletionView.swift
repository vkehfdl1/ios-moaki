import SwiftUI

struct TutorialCompletionView: View {
    let onRestart: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var freeText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("자유 연습")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("모아키 제스처를 거의 마스터하셨습니다!\n자유롭게 아무 글자나 입력해보세요.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 12)

            TextEditor(text: $freeText)
                .font(.system(size: 18))
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .focused($isFocused)
                .padding(.horizontal, 16)

            HStack(spacing: 12) {
                Button(action: onRestart) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("다시 시작")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 1.5)
                    )
                }

                Button {
                    dismiss()
                } label: {
                    Text("종료")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}
