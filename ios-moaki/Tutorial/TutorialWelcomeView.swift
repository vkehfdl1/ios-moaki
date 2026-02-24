import SwiftUI

struct TutorialWelcomeView: View {
    let stage: TutorialStage
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "keyboard")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text(stage.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }

            Text(stage.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "hand.draw")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("자음 키를 누르고 슬라이드하면\n모음이 입력됩니다")
                        .font(.callout)
                        .multilineTextAlignment(.leading)
                }

                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("방향을 바꿔가며 드래그하면\n다양한 모음을 만들 수 있습니다")
                        .font(.callout)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal, 16)

            Spacer()

            Button(action: onStart) {
                Text("시작하기")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}
