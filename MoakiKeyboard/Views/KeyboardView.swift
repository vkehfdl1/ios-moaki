import SwiftUI
import Combine

struct KeyboardView: View {
    @ObservedObject var viewModel: KeyboardViewModel
    @ObservedObject var settings = KeyboardSettings.shared

    var body: some View {
        GeometryReader { geometry in
            let centerKeyWidth = KeyboardMetrics.centerKeyWidth(for: geometry.size.width)
            let keyHeight = KeyboardMetrics.keyHeight(for: geometry.size.height)

            ZStack {
                VStack(spacing: KeyboardMetrics.keySpacing) {
                    // Key grid (consonants or symbols based on mode)
                    KeyGridView(
                        centerKeyWidth: centerKeyWidth,
                        keyHeight: keyHeight,
                        totalWidth: geometry.size.width,
                        isSymbolMode: viewModel.isSymbolMode,
                        activeKey: viewModel.activeKey,
                        previewVowel: viewModel.previewVowel,
                        onConsonantTap: { consonant in
                            viewModel.inputConsonant(consonant)
                        },
                        onSymbolTap: { symbol in
                            viewModel.inputSymbol(symbol)
                        },
                        onBackspace: {
                            viewModel.deleteBackward()
                        },
                        onLongPressNumber: { number in
                            viewModel.inputNumber(number)
                        },
                        onGestureStart: { row, column, point in
                            viewModel.gestureStarted(row: row, column: column, at: point)
                        },
                        onGestureMove: { point in
                            viewModel.gestureMoved(to: point)
                        },
                        onGestureEnd: { row, column in
                            viewModel.gestureEnded(row: row, column: column)
                        }
                    )

                    // Function row
                    FunctionRowView(
                        totalWidth: geometry.size.width,
                        isSymbolMode: viewModel.isSymbolMode,
                        onToggleModePressed: {
                            viewModel.toggleMode()
                        },
                        onCommaPressed: {
                            viewModel.inputSymbol(",")
                        },
                        onSpacePressed: {
                            viewModel.inputSpace()
                        },
                        onReturnPressed: {
                            viewModel.inputReturn()
                        }
                    )
                }
                .padding(KeyboardMetrics.keySpacing)

                // Gesture overlay (only shown when enabled and in Korean mode)
                if settings.showGesturePreview && !viewModel.isSymbolMode {
                    GestureOverlayView(
                        directions: viewModel.gestureDirections,
                        startPoint: viewModel.gestureStartPoint,
                        currentVowel: viewModel.previewVowel
                    )
                }
            }
            .background(Color(.systemGray6))
        }
    }
}

// ViewModel to handle keyboard logic
class KeyboardViewModel: ObservableObject {
    @Published var activeKey: (row: Int, column: Int)?
    @Published var previewVowel: Jungseong?
    @Published var gestureDirections: [GestureDirection] = []
    @Published var gestureStartPoint: CGPoint?
    @Published var isSymbolMode: Bool = false

    private let composer = HangulComposer()
    private let gestureAnalyzer = GestureAnalyzer()
    private let vowelResolver = VowelResolver()

    /// Tracks the last composing text to enable incremental updates
    private var lastComposingText: String = ""

    weak var delegate: KeyboardViewModelDelegate?

    var composingText: String {
        composer.displayText
    }

    // MARK: - Mode Toggle

    func toggleMode() {
        commitCurrent()
        isSymbolMode.toggle()
        triggerHapticFeedback()
    }

    // MARK: - Input Methods

    func inputConsonant(_ consonant: Choseong) {
        let action = composer.inputChoseong(consonant)
        handleComposerAction(action)
        triggerHapticFeedback()
    }

    func inputVowel(_ vowel: Jungseong) {
        let action = composer.inputJungseong(vowel)
        handleComposerAction(action)
        triggerHapticFeedback()
    }

    func inputSymbol(_ symbol: String) {
        commitCurrent()
        delegate?.insertText(symbol)
        triggerHapticFeedback()
    }

    func inputNumber(_ number: String) {
        commitCurrent()
        delegate?.insertText(number)
        triggerHapticFeedback()
    }

    func deleteBackward() {
        let action = composer.deleteBackward()
        if action == .none {
            delegate?.deleteBackward()
        } else {
            handleComposerAction(action)
        }
        triggerHapticFeedback()
    }

    func inputSpace() {
        commitAndInsert(" ")
        triggerHapticFeedback()
    }

    func inputReturn() {
        commitAndInsert("\n")
        triggerHapticFeedback()
    }

    func switchKeyboard() {
        commitCurrent()
        delegate?.switchToNextKeyboard()
    }

    // MARK: - Gesture Handling

    func gestureStarted(row: Int, column: Int, at point: CGPoint) {
        activeKey = (row, column)
        gestureStartPoint = point
        gestureAnalyzer.reset()
        gestureAnalyzer.addPoint(point)
        gestureDirections = []
        previewVowel = nil
    }

    func gestureMoved(to point: CGPoint) {
        gestureAnalyzer.addPoint(point)
        let directions = gestureAnalyzer.getDirections()
        gestureDirections = directions

        // Update preview vowel (only meaningful for consonant keys)
        previewVowel = vowelResolver.peekVowel(directions: directions)
    }

    func gestureEnded(row: Int, column: Int) {
        // In symbol mode, gesture handling is simpler - just tap
        if isSymbolMode {
            handleSymbolModeTap(row: row, column: column)
        } else {
            handleKoreanModeGesture(row: row, column: column)
        }

        // Reset gesture state
        activeKey = nil
        gestureStartPoint = nil
        gestureDirections = []
        previewVowel = nil
    }

    private func handleSymbolModeTap(row: Int, column: Int) {
        guard let content = KeyboardMetrics.keyContent(at: row, column: column, isSymbolMode: true) else { return }

        switch content {
        case .symbol(let symbol):
            inputSymbol(symbol)
        case .backspace:
            deleteBackward()
        case .consonant:
            break // Should not happen in symbol mode
        }
    }

    private func handleKoreanModeGesture(row: Int, column: Int) {
        let directions = gestureAnalyzer.finalizeGesture()

        guard let content = KeyboardMetrics.keyContent(at: row, column: column, isSymbolMode: false) else { return }

        switch content {
        case .consonant(let consonant):
            if directions.isEmpty {
                // No gesture - treat as tap
                inputConsonant(consonant)
            } else {
                // Gesture completed - input consonant + vowel
                inputConsonant(consonant)

                let resolution = vowelResolver.resolve(directions: directions)
                if let vowel = resolution.vowel {
                    inputVowel(vowel)
                }
            }

        case .symbol(let symbol):
            inputSymbol(symbol)

        case .backspace:
            deleteBackward()
        }
    }

    // MARK: - Public State Reset (for external text field changes)

    func resetComposer() {
        // Reset composer state when text field changes externally
        // (e.g., when user sends a message and the app clears the field)
        lastComposingText = ""
        composer.reset()
    }

    func resetGestureState() {
        activeKey = nil
        gestureStartPoint = nil
        gestureDirections = []
        previewVowel = nil
        gestureAnalyzer.reset()
    }

    // MARK: - Private Helpers

    private func handleComposerAction(_ action: HangulComposer.ComposerAction) {
        switch action {
        case .none:
            break
        case .update:
            updateComposingText()
        case .commit, .commitAndUpdate, .commitAndCommit:
            let committed = composer.flushCommittedText()

            // 1. First, delete the composing text currently on screen
            for _ in lastComposingText {
                delegate?.deleteBackward()
            }
            lastComposingText = ""

            // 2. Insert the committed text
            if !committed.isEmpty {
                delegate?.insertText(committed)
            }

            // 3. Update with the new composing character (if any)
            updateComposingText()
        case .delete:
            // If there's composing text, delete it; otherwise pass through to delegate
            if !lastComposingText.isEmpty {
                // Clear the composing text from screen
                for _ in lastComposingText {
                    delegate?.deleteBackward()
                }
                lastComposingText = ""
            } else {
                delegate?.deleteBackward()
            }
            updateComposingText()
        }
    }

    private func updateComposingText() {
        let composing = composer.currentComposingCharacter.map { String($0) } ?? ""
        let previous = lastComposingText
        lastComposingText = composing
        delegate?.updateComposingText(from: previous, to: composing)
    }

    private func commitCurrent() {
        // The composing character is already on screen, so just reset state
        // without inserting it again
        lastComposingText = ""
        composer.reset()
    }

    private func commitAndInsert(_ text: String) {
        commitCurrent()
        delegate?.insertText(text)
    }

    private func triggerHapticFeedback() {
        delegate?.triggerHapticFeedback()
    }
}

protocol KeyboardViewModelDelegate: AnyObject {
    func insertText(_ text: String)
    func deleteBackward()
    func updateComposingText(from previous: String, to current: String)
    func switchToNextKeyboard()
    func triggerHapticFeedback()
}

#Preview {
    KeyboardView(viewModel: KeyboardViewModel())
        .frame(height: 280)
}
