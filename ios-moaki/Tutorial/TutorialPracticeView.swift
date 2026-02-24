import SwiftUI

struct TutorialPracticeView: View {
    @ObservedObject var viewModel: TutorialViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stage title and description
                VStack(spacing: 8) {
                    Text(viewModel.currentStage.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(viewModel.currentStage.description)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                // Vowel gesture cards
                if !viewModel.currentStage.vowelGestures.isEmpty {
                    let columns = Array(
                        repeating: GridItem(.flexible(), spacing: 8),
                        count: min(viewModel.currentStage.vowelGestures.count, 4)
                    )
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(viewModel.currentStage.vowelGestures) { gesture in
                            VowelGestureCard(gesture: gesture)
                        }
                    }
                    .padding(.horizontal, 12)
                }

                // Keyboard switch banner
                keyboardBanner

                // Practice area
                if viewModel.hasPractice && !viewModel.stageCompleted {
                    practiceSection
                }

                // Stage completed
                if viewModel.stageCompleted {
                    stageCompletedSection
                }
            }
            .padding(.vertical, 16)
        }
        .onAppear {
            viewModel.startStage()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
    }

    private var keyboardBanner: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .foregroundColor(.blue)
                Text("🌐 버튼을 눌러 모아키 키보드로 전환하세요")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.showKeyboardWarning {
                Text("모아키 키보드로 전환해주세요")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 16)
    }

    private var practiceSection: some View {
        VStack(spacing: 16) {
            // Target text with character comparison
            CharacterComparisonView(
                target: viewModel.currentTargetLine,
                states: viewModel.characterStates
            )
            .padding(.horizontal, 16)

            // Input field
            PracticeInputField(
                text: $viewModel.inputText,
                isFocused: $isInputFocused
            )
            .padding(.horizontal, 16)

            // Line progress
            HStack {
                Text("\(viewModel.currentLineIndex + 1)/\(viewModel.totalLines) 줄")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if viewModel.lineCompleted {
                    Button {
                        viewModel.advanceToNextLine()
                        isInputFocused = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("다음")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var stageCompletedSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("잘하셨습니다!")
                .font(.title3)
                .fontWeight(.bold)

            Button {
                viewModel.advanceToNextStage()
            } label: {
                Text("다음 단계로")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 20)
    }
}
