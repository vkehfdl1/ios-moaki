import SwiftUI

struct TutorialContainerView: View {
    @StateObject private var viewModel = TutorialViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            if !viewModel.isCompletion {
                ProgressView(value: viewModel.overallProgress)
                    .tint(.blue)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }

            // Stage content
            Group {
                if viewModel.isCompletion {
                    TutorialCompletionView(onRestart: viewModel.restart)
                } else if viewModel.isWelcome {
                    TutorialWelcomeView(
                        stage: viewModel.currentStage,
                        onStart: viewModel.advanceToNextStage
                    )
                } else {
                    TutorialPracticeView(viewModel: viewModel)
                }
            }
        }
        .navigationTitle("키보드 튜토리얼")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}
