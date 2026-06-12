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
                    // Word prediction suggestions (top bar)
                    SuggestionBarView(
                        suggestions: viewModel.suggestions,
                        onSelect: { viewModel.selectSuggestion($0) }
                    )

                    // Key grid (consonants, symbols, or letters based on mode)
                    KeyGridView(
                        centerKeyWidth: centerKeyWidth,
                        keyHeight: keyHeight,
                        totalWidth: geometry.size.width,
                        mode: viewModel.mode,
                        activeKey: viewModel.activeKey,
                        previewVowel: viewModel.previewVowel,
                        hintOptions: viewModel.hintOptions,
                        hintAnchor: viewModel.hintAnchor,
                        isShiftEnabled: viewModel.isShiftEnabled,
                        onConsonantTap: { consonant in
                            viewModel.inputConsonant(consonant)
                        },
                        onSymbolTap: { symbol in
                            viewModel.inputSymbol(symbol)
                        },
                        onBackspacePressStart: {
                            viewModel.beginBackspacePress()
                        },
                        onBackspacePressEnd: {
                            viewModel.endBackspacePress()
                        },
                        onLongPressNumber: { number in
                            viewModel.inputLongPressNumber(number)
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
                        mode: viewModel.mode,
                        onSwitchMode: { newMode in
                            viewModel.switchMode(to: newMode)
                        },
                        onCommaPressed: {
                            viewModel.inputSymbol(",")
                        },
                        onSpacePressed: {
                            viewModel.inputSpace()
                        },
                        onReturnPressed: {
                            viewModel.inputReturn()
                        },
                        onSnippetPressed: {
                            viewModel.toggleSnippets()
                        }
                    )
                }
                .padding(KeyboardMetrics.keySpacing)

                // Gesture overlay (only shown when enabled and in Korean mode)
                if settings.showGesturePreview && viewModel.mode == .korean {
                    GestureOverlayView(
                        directions: viewModel.gestureDirections,
                        startPoint: viewModel.gestureStartPoint,
                        currentVowel: viewModel.previewVowel
                    )
                }

                // Live syllable preview: shows the consonant+vowel being typed,
                // large at top-center, so the user can correct before lifting.
                if viewModel.mode == .korean,
                   let active = viewModel.activeKey,
                   let cho = KeyboardMetrics.consonant(at: active.row, column: active.column) {
                    let preview: Character = viewModel.previewVowel
                        .map { HangulConstants.composeSyllable(choseong: cho, jungseong: $0) }
                        ?? cho.compatibilityCharacter
                    VStack {
                        Text(String(preview))
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 92, minHeight: 92)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.black.opacity(0.72))
                                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                            )
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }

                // 상용어 패널 (키보드 영역 덮는 오버레이)
                if viewModel.showSnippets {
                    SnippetPanelView(
                        snippets: viewModel.snippets,
                        maxCount: SnippetStore.shared.maxCount,
                        onInsert: { viewModel.insertSnippet($0) },
                        onAdd: { viewModel.addCurrentLineAsSnippet() },
                        onRemove: { viewModel.removeSnippet(at: $0) },
                        onClose: { viewModel.showSnippets = false }
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
    @Published var mode: KeyboardMode = .korean
    @Published var hintOptions: [VowelOption] = []
    @Published var hintAnchor: CGPoint?
    @Published var showSnippets = false
    @Published var snippets: [String] = []
    @Published var suggestions: [String] = []
    /// English mode: one-shot shift. Tap shift, next letter is uppercase, then auto-resets.
    @Published var isShiftEnabled = false

    private let composer = HangulComposer()
    private var gestureAnalyzer: GestureRecognizing = GestureAnalyzer()
    private let vowelResolver = VowelResolver()

    /// Tracks the last composing text to enable incremental updates
    private var lastComposingText: String = ""

    private let backspaceRepeatInitialDelay: TimeInterval
    private let backspaceRepeatInterval: TimeInterval
    private var isBackspacePressing = false
    private var backspaceInitialDelayTimer: Timer?
    private var backspaceRepeatTimer: Timer?
    private var didHandleLongPressNumberInCurrentGesture = false

    weak var delegate: KeyboardViewModelDelegate?

    init(backspaceRepeatInitialDelay: TimeInterval = 0.4, backspaceRepeatInterval: TimeInterval = 0.08) {
        self.backspaceRepeatInitialDelay = backspaceRepeatInitialDelay
        self.backspaceRepeatInterval = backspaceRepeatInterval
    }

    deinit {
        stopBackspaceRepeat()
    }

    var composingText: String {
        composer.displayText
    }

    // MARK: - Mode Toggle

    func switchMode(to newMode: KeyboardMode) {
        guard newMode != mode else { return }
        stopBackspaceRepeat()
        commitCurrent()
        mode = newMode
        isShiftEnabled = false  // Don't carry English shift latch into other modes.
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
        learnCurrentWord()
        commitCurrent()
        delegate?.insertText(symbol)
        updateSuggestions()
        triggerHapticFeedback()
    }

    /// English letters: plain insert, no word-boundary learning (letters aren't separators).
    func inputLetter(_ letter: String) {
        commitCurrent()
        delegate?.insertText(letter)
        updateSuggestions()
        triggerHapticFeedback()
    }

    func inputNumber(_ number: String) {
        commitCurrent()
        delegate?.insertText(number)
        triggerHapticFeedback()
    }

    func inputLongPressNumber(_ number: String) {
        didHandleLongPressNumberInCurrentGesture = true
        inputNumber(number)
    }

    func deleteBackward() {
        let action = composer.deleteBackward()
        if action == .none {
            delegate?.deleteBackward()
            updateSuggestions()
        } else {
            handleComposerAction(action)
        }
        triggerHapticFeedback()
    }

    func inputSpace() {
        learnCurrentWord()
        commitAndInsert(" ")
        updateSuggestions()
        triggerHapticFeedback()
    }

    func inputReturn() {
        learnCurrentWord()
        commitAndInsert("\n")
        updateSuggestions()
        triggerHapticFeedback()
    }

    func switchKeyboard() {
        stopBackspaceRepeat()
        commitCurrent()
        delegate?.switchToNextKeyboard()
    }

    func beginBackspacePress() {
        guard !isBackspacePressing else { return }

        isBackspacePressing = true
        deleteBackward()  // Immediate delete on touch-down.
        startBackspaceRepeat()
    }

    func endBackspacePress() {
        stopBackspaceRepeat()
    }

    // MARK: - Gesture Handling

    func gestureStarted(row: Int, column: Int, at point: CGPoint) {
        didHandleLongPressNumberInCurrentGesture = false
        activeKey = (row, column)
        gestureStartPoint = point
        // Pick the recognizer per gesture so a settings change applies immediately.
        gestureAnalyzer = KeyboardSettings.shared.useGridRecognition
            ? GridGestureAnalyzer()
            : GestureAnalyzer()
        gestureAnalyzer.reset()
        gestureAnalyzer.addPoint(point)
        gestureDirections = []
        previewVowel = nil
        hintOptions = mode == .korean ? vowelResolver.nextOptions(directions: []) : []
        hintAnchor = nil
    }

    func gestureMoved(to point: CGPoint) {
        gestureAnalyzer.addPoint(point)
        let directions = gestureAnalyzer.getDirections()
        gestureDirections = directions

        guard mode == .korean else { return }

        // Update preview vowel (only meaningful for consonant keys)
        previewVowel = vowelResolver.peekVowel(directions: directions)

        // Initial vowels anchor at the key; once a stroke begins the follow-on
        // vowels (ㅐ ㅑ …) anchor at the finger so they appear around it.
        hintOptions = vowelResolver.nextOptions(directions: directions)
        hintAnchor = directions.isEmpty ? nil : point
    }

    func gestureEnded(row: Int, column: Int) {
        if didHandleLongPressNumberInCurrentGesture {
            didHandleLongPressNumberInCurrentGesture = false
            resetGestureState()
            return
        }

        switch mode {
        case .korean:
            handleKoreanModeGesture(row: row, column: column)
        case .symbol:
            handleSymbolModeTap(row: row, column: column)
        case .english:
            handleEnglishModeGesture(row: row, column: column)
        }

        resetGestureState()
    }

    private func handleSymbolModeTap(row: Int, column: Int) {
        guard let content = KeyboardMetrics.keyContent(at: row, column: column, mode: .symbol) else { return }

        switch content {
        case .symbol(let symbol):
            inputSymbol(symbol)
        case .backspace:
            deleteBackward()
        case .consonant, .shift:
            break // Should not happen in symbol mode
        }
    }

    /// English mode: tap = lowercase, drag starting upward = uppercase, shift = one-shot uppercase.
    private func handleEnglishModeGesture(row: Int, column: Int) {
        let directions = gestureAnalyzer.finalizeGesture()

        guard let content = KeyboardMetrics.keyContent(at: row, column: column, mode: .english) else { return }

        switch content {
        case .symbol(let letter):
            let dragUpper = directions.first.map { [.up, .upLeft, .upRight].contains($0) } ?? false
            let isUppercase = dragUpper || isShiftEnabled
            inputLetter(isUppercase ? letter.uppercased() : letter)
            // One-shot shift: consume after a letter is typed.
            if isShiftEnabled { isShiftEnabled = false }
        case .backspace:
            deleteBackward()
        case .shift:
            isShiftEnabled.toggle()
            triggerHapticFeedback()
        case .consonant:
            break // Should not happen in english mode
        }
    }

    private func handleKoreanModeGesture(row: Int, column: Int) {
        let directions = gestureAnalyzer.finalizeGesture()

        guard let content = KeyboardMetrics.keyContent(at: row, column: column, mode: .korean) else { return }

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

        case .shift:
            break // Shift not used in Korean mode (쌍자음 are direct keys).
        }
    }

    // MARK: - Public State Reset (for external text field changes)

    func resetComposer() {
        // Reset composer state when text field changes externally
        // (e.g., when user sends a message and the app clears the field)
        stopBackspaceRepeat()
        lastComposingText = ""
        composer.reset()
    }

    /// Resets gesture tracking state only. Intentionally does NOT reset composer
    /// or lastComposingText to preserve in-progress Hangul composition.
    func resetGestureState() {
        stopBackspaceRepeat()
        didHandleLongPressNumberInCurrentGesture = false
        activeKey = nil
        gestureStartPoint = nil
        gestureDirections = []
        previewVowel = nil
        hintOptions = []
        hintAnchor = nil
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
        updateSuggestions()
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

    // MARK: - Snippets (상용어)

    func toggleSnippets() {
        if !showSnippets { snippets = SnippetStore.shared.all }
        showSnippets.toggle()
        triggerHapticFeedback()
    }

    func insertSnippet(_ text: String) {
        commitCurrent()
        delegate?.insertText(text)
        showSnippets = false
        triggerHapticFeedback()
    }

    /// 입력창에 지금 친 줄을 상용어로 캡처 (익스텐션은 자체 텍스트 입력이 어려워서).
    func addCurrentLineAsSnippet() {
        guard let before = delegate?.documentContextBeforeInput else { return }
        let line = before.components(separatedBy: .newlines).last ?? before
        if SnippetStore.shared.add(line) {
            snippets = SnippetStore.shared.all
        }
    }

    func removeSnippet(at index: Int) {
        SnippetStore.shared.remove(at: index)
        snippets = SnippetStore.shared.all
    }

    // MARK: - 단어 예측

    /// 후보 선택: 지금 친 prefix를 지우고 단어를 통째로 삽입.
    func selectSuggestion(_ word: String) {
        guard let before = delegate?.documentContextBeforeInput else { return }
        let prefix = before.components(separatedBy: Self.wordSeparators).last ?? ""
        composer.reset()
        lastComposingText = ""
        for _ in prefix { delegate?.deleteBackward() }
        delegate?.insertText(word)
        suggestions = []
        triggerHapticFeedback()
    }

    /// 커서 앞 현재 단어(prefix)로 사전을 검색해 후보를 갱신.
    /// proxy(documentContextBeforeInput)는 insert/delete 직후엔 아직 옛 값이라,
    /// 다음 런루프에서 갱신된 값을 읽는다.
    private func updateSuggestions() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let before = self.delegate?.documentContextBeforeInput ?? ""
            let prefix = before.components(separatedBy: Self.wordSeparators).last ?? ""
            self.suggestions = prefix.isEmpty ? [] : WordStore.shared.suggestions(prefix: prefix)
        }
    }

    private static let wordSeparators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)

    /// 단어 확정 시점(공백·줄바꿈·구두점)에 커서 앞 마지막 단어를 사전에 학습시킨다.
    /// proxy 갱신을 기다려 다음 런루프에서 읽고, 끝의 공백/구두점은 걸러 단어만 추출.
    private func learnCurrentWord() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let before = self.delegate?.documentContextBeforeInput else { return }
            let parts = before.components(separatedBy: Self.wordSeparators).filter { !$0.isEmpty }
            if let word = parts.last { WordStore.shared.record(word) }
        }
    }

    private func triggerHapticFeedback() {
        delegate?.triggerHapticFeedback()
    }

    private func startBackspaceRepeat() {
        backspaceInitialDelayTimer?.invalidate()
        backspaceInitialDelayTimer = makeTimer(interval: backspaceRepeatInitialDelay, repeats: false) { [weak self] _ in
            guard let self, self.isBackspacePressing else { return }

            self.backspaceRepeatTimer?.invalidate()
            self.backspaceRepeatTimer = self.makeTimer(interval: self.backspaceRepeatInterval, repeats: true) { [weak self] _ in
                guard let self, self.isBackspacePressing else { return }
                self.deleteBackward()
            }
        }
    }

    private func stopBackspaceRepeat() {
        isBackspacePressing = false
        backspaceInitialDelayTimer?.invalidate()
        backspaceInitialDelayTimer = nil
        backspaceRepeatTimer?.invalidate()
        backspaceRepeatTimer = nil
    }

    private func makeTimer(interval: TimeInterval, repeats: Bool, handler: @escaping (Timer) -> Void) -> Timer {
        let timer = Timer(timeInterval: interval, repeats: repeats, block: handler)
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }
}

protocol KeyboardViewModelDelegate: AnyObject {
    func insertText(_ text: String)
    func deleteBackward()
    func updateComposingText(from previous: String, to current: String)
    func switchToNextKeyboard()
    func triggerHapticFeedback()
    var documentContextBeforeInput: String? { get }
}

#Preview {
    KeyboardView(viewModel: KeyboardViewModel())
        .frame(height: 280)
}
