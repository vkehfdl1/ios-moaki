import SwiftUI
import Combine

@MainActor
final class TutorialViewModel: ObservableObject {
    @Published var currentStageIndex: Int = 0
    @Published var inputText: String = "" {
        didSet { evaluateInput() }
    }
    @Published var currentLineIndex: Int = 0
    @Published var lineCompleted: Bool = false
    @Published var stageCompleted: Bool = false
    @Published var characterStates: [CharacterState] = []
    @Published var showKeyboardWarning: Bool = false

    enum CharacterState {
        case pending
        case correct
        case incorrect
        case composing
    }

    var stages: [TutorialStage] { TutorialContent.stages }
    var isWelcome: Bool { currentStageIndex == 0 }
    var isCompletion: Bool { currentStageIndex >= stages.count }

    var currentStage: TutorialStage {
        guard currentStageIndex < stages.count else { return stages.last! }
        return stages[currentStageIndex]
    }

    var hasPractice: Bool { !currentStage.practiceLines.isEmpty }

    var currentTargetLine: String {
        let lines = currentStage.practiceLines
        guard currentLineIndex < lines.count else { return "" }
        return lines[currentLineIndex]
    }

    var totalLines: Int { currentStage.practiceLines.count }

    var overallProgress: Double {
        guard !stages.isEmpty else { return 0 }
        return Double(currentStageIndex) / Double(stages.count)
    }

    func startStage() {
        currentLineIndex = 0
        inputText = ""
        lineCompleted = false
        stageCompleted = false
        updateCharacterStates()
    }

    func advanceToNextStage() {
        currentStageIndex += 1
        if !isCompletion {
            startStage()
        }
    }

    func advanceToNextLine() {
        currentLineIndex += 1
        inputText = ""
        lineCompleted = false
        if currentLineIndex >= totalLines {
            stageCompleted = true
        } else {
            updateCharacterStates()
        }
    }

    func restart() {
        currentStageIndex = 0
        startStage()
    }

    private func evaluateInput() {
        detectNonKoreanInput()
        updateCharacterStates()
        checkLineCompletion()
    }

    private func detectNonKoreanInput() {
        guard !inputText.isEmpty else {
            showKeyboardWarning = false
            return
        }
        let lastChar = inputText.last!
        let isKorean = HangulUnicode.isHangulSyllable(lastChar)
            || isHangulJamo(lastChar)
        showKeyboardWarning = !isKorean
    }

    private func isHangulJamo(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        let value = scalar.value
        return value >= 0x3130 && value <= 0x318F
    }

    private func updateCharacterStates() {
        let target = Array(currentTargetLine)
        let input = Array(inputText)
        var states: [CharacterState] = []

        for (index, targetChar) in target.enumerated() {
            if index >= input.count {
                states.append(.pending)
            } else if index == input.count - 1
                        && HangulUnicode.isPartialMatch(input: input[index], target: targetChar) {
                states.append(.composing)
            } else if input[index] == targetChar {
                states.append(.correct)
            } else {
                states.append(.incorrect)
            }
        }

        characterStates = states
    }

    private func checkLineCompletion() {
        guard !currentTargetLine.isEmpty else { return }
        if inputText == currentTargetLine {
            lineCompleted = true
        }
    }
}
