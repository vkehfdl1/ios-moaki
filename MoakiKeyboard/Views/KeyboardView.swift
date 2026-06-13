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

                    // Key grid (consonants or symbols based on mode)
                    KeyGridView(
                        centerKeyWidth: centerKeyWidth,
                        keyHeight: keyHeight,
                        totalWidth: geometry.size.width,
                        isSymbolMode: viewModel.isSymbolMode,
                        popupPhase: viewModel.popupPhase,
                        activeKey: viewModel.activeKey,
                        previewVowel: viewModel.previewVowel,
                        hintOptions: viewModel.hintOptions,
                        hintAnchor: viewModel.hintAnchor,
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
                            viewModel.gestureStarted(row: row, column: column, at: point,
                                                     totalWidth: geometry.size.width,
                                                     centerKeyWidth: centerKeyWidth,
                                                     keyHeight: keyHeight)
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
                        },
                        onSnippetPressed: {
                            viewModel.toggleSnippets()
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

                // Live syllable preview: shows the consonant+vowel being typed,
                // large at top-center, so the user can correct before lifting.
                // In popup mode the popup itself acts as preview, so suppress here.
                if !viewModel.isSymbolMode,
                   viewModel.popupPhase == .idle,
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

/// Vowel-popup mode interaction phases.
///
/// New STATIC design (replaces the old cascade-reflow):
/// - `.idle`: no popup gesture active. The grid renders normally.
/// - `.selecting`: finger is down on a consonant key. Vowel hints brighten.
///   On release: commit C + (current cell's static vowel) — or C alone if
///   the current cell has no vowel mapping (then composer auto-routes).
/// - `.batchim`: after selecting C+V, the finger drifted onto another
///   consonant cell. On release there: commit C + V + (that consonant) as
///   batchim.
enum PopupPhase: Equatable {
    case idle
    case selecting(origin: (row: Int, column: Int), choseong: Choseong, hasMoved: Bool, currentCell: (row: Int, column: Int)?)
    case batchim(origin: (row: Int, column: Int), choseong: Choseong, jungseong: Jungseong)

    static func == (lhs: PopupPhase, rhs: PopupPhase) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case let (.selecting(lo, lc, lm, lcc), .selecting(ro, rc, rm, rcc)):
            return lo == ro && lc == rc && lm == rm
                && lcc?.row == rcc?.row && lcc?.column == rcc?.column
        case let (.batchim(lo, lc, lj), .batchim(ro, rc, rj)):
            return lo == ro && lc == rc && lj == rj
        default: return false
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
    @Published var hintOptions: [VowelOption] = []
    @Published var hintAnchor: CGPoint?
    @Published var showSnippets = false
    @Published var snippets: [String] = []
    @Published var suggestions: [String] = []
    /// Current phase for vowel-popup mode (only meaningful when
    /// KeyboardSettings.useVowelPopupMode == true).
    @Published var popupPhase: PopupPhase = .idle

    /// Grid metrics captured during gesture start, used to hit-test the finger
    /// against grid cells during popup-mode drags. nil outside an active drag.
    private var gridTotalWidth: CGFloat?
    private var gridCenterKeyWidth: CGFloat?
    private var gridKeyHeight: CGFloat?
    /// Last cell the finger was over while popup is active.
    private var popupCurrentCell: (row: Int, column: Int)?
    /// Tracks the last vowel cell the finger crossed; used to decide which
    /// vowel to commit when the user drags back to a consonant for batchim.
    private var popupLastVowelOver: Jungseong?

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

    func toggleMode() {
        stopBackspaceRepeat()
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
        learnCurrentWord()
        commitCurrent()
        delegate?.insertText(symbol)
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

    /// Called by the view when a touch begins on `(row, column)`. The grid
    /// metrics let the ViewModel hit-test the finger against cells later.
    func gestureStarted(row: Int, column: Int, at point: CGPoint,
                        totalWidth: CGFloat = 0, centerKeyWidth: CGFloat = 0, keyHeight: CGFloat = 0) {
        didHandleLongPressNumberInCurrentGesture = false
        activeKey = (row, column)
        gestureStartPoint = point
        gridTotalWidth = totalWidth
        gridCenterKeyWidth = centerKeyWidth
        gridKeyHeight = keyHeight

        // ─── VOWEL POPUP MODE ───────────────────────────────────────────────
        // STATIC design: on touch-down over a consonant cell, enter the
        // .selecting phase. The current cell's static vowel is what gets
        // committed on release-in-place (the "hidden vowel" mechanic).
        //
        // Bypass if the composer is currently CV-OPEN (.choseongJungseong):
        // a tap there must attach as 받침 via the composer's existing
        // routing (preserves the b4d258e fix). Drop straight through to
        // inputConsonant.
        if !isSymbolMode,
           KeyboardSettings.shared.useVowelPopupMode,
           case .consonant(let cho) = KeyboardMetrics.keyContent(at: row, column: column, isSymbolMode: false) ?? .symbol("") {
            if case .choseongJungseong = composer.state {
                // CV-OPEN — tap-as-batchim path. Don't engage selecting.
                inputConsonant(cho)
                triggerHapticFeedback()
                return
            }
            popupPhase = .selecting(origin: (row, column), choseong: cho, hasMoved: false, currentCell: (row, column))
            popupCurrentCell = (row, column)
            popupLastVowelOver = nil
            triggerHapticFeedback()
            return
        }

        // ─── GESTURE (legacy) MODE ──────────────────────────────────────────
        // Pick the recognizer per gesture so a settings change applies immediately.
        gestureAnalyzer = KeyboardSettings.shared.useGridRecognition
            ? GridGestureAnalyzer()
            : GestureAnalyzer()
        gestureAnalyzer.reset()
        gestureAnalyzer.addPoint(point)
        gestureDirections = []
        previewVowel = nil
        hintOptions = vowelResolver.nextOptions(directions: [])
        hintAnchor = nil
    }

    /// `point` is in the keyboardGrid coordinate space when popup mode is
    /// active, or the originating key's local space otherwise.
    func gestureMoved(to point: CGPoint) {
        // ─── POPUP MODE: hit-test against grid cells ───────────────────────
        if popupPhase != .idle {
            handlePopupMove(at: point)
            return
        }

        gestureAnalyzer.addPoint(point)
        let directions = gestureAnalyzer.getDirections()
        gestureDirections = directions

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

        // ─── POPUP MODE: commit based on what's under the finger ───────────
        if popupPhase != .idle {
            handlePopupEnd()
            return
        }

        // In symbol mode, gesture handling is simpler - just tap
        if isSymbolMode {
            handleSymbolModeTap(row: row, column: column)
        } else {
            handleKoreanModeGesture(row: row, column: column)
        }

        resetGestureState()
    }

    // MARK: - Vowel Popup Mode Handling (STATIC design)
    //
    // Phases:
    //  .idle        — popup not active
    //  .selecting   — finger down on a consonant. Track currentCell + hasMoved.
    //                 On release: commit C + vowelFor(currentCell) when
    //                 currentCell has a vowel mapping. Tap-in-place uses the
    //                 source cell's own vowel.
    //  .batchim     — after selecting committed a CV (i.e. user dragged
    //                 onto a vowel slot, then further onto a consonant slot
    //                 — captured by inspecting the next cell during drag).
    //                 We DON'T enter this aggressively; the simpler tap-then-
    //                 tap path (preserve b4d258e) covers the common 받침 case.
    //
    // Note: the .batchim path is reachable only if the user explicitly drags
    // back onto a consonant cell AFTER passing through a vowel cell, in a
    // single continuous gesture. This is intentionally narrow — the common
    // 받침 path is "type CV, then tap consonant" which is handled by the
    // composer's CV-OPEN routing.

    private func handlePopupMove(at point: CGPoint) {
        guard let cell = cell(at: point) else { return }
        popupCurrentCell = cell

        switch popupPhase {
        case .idle:
            return
        case .selecting(let origin, let cho, let hadMoved, _):
            let moved = hadMoved || (cell.row != origin.row || cell.column != origin.column)
            // Track most recently-crossed vowel (used by .batchim transition).
            if let v = KeyboardMetrics.vowelFor(row: cell.row, column: cell.column) {
                popupLastVowelOver = v
            }
            // If after crossing a vowel the finger lands on a different
            // consonant cell, transition to .batchim.
            if let last = popupLastVowelOver,
               let _ = consonantAt(row: cell.row, column: cell.column),
               !(cell.row == origin.row && cell.column == origin.column) {
                popupPhase = .batchim(origin: origin, choseong: cho, jungseong: last)
                triggerHapticFeedback()
                return
            }
            popupPhase = .selecting(origin: origin, choseong: cho, hasMoved: moved, currentCell: cell)
        case .batchim:
            // Stay in batchim; just track the current cell (already updated).
            break
        }
    }

    private func handlePopupEnd() {
        // Capture state, then reset before any input (input also triggers UI redraw).
        let phase = popupPhase
        let cell = popupCurrentCell
        popupPhase = .idle
        popupCurrentCell = nil
        popupLastVowelOver = nil

        guard let cell = cell else { resetGestureState(); return }

        switch phase {
        case .idle:
            break
        case .selecting(let origin, let cho, let hasMoved, _):
            // Hidden-vowel mechanic: use the cell-under-finger's static vowel.
            // - Tap-in-place: cell == origin -> origin's own vowel.
            // - Drag-to-vowel-slot: cell's vowel.
            // - Drag-off to symbol cell with no vowel: input symbol (skip C).
            // - Drag-off to ⌫: backspace.
            let landingVowel = KeyboardMetrics.vowelFor(row: cell.row, column: cell.column)
            if !hasMoved {
                // Tap-in-place. Use origin's vowel (== cell's vowel here).
                if let v = landingVowel {
                    inputConsonant(cho)
                    inputVowel(v)
                } else {
                    // Origin has no vowel mapping (shouldn't happen for
                    // consonant cells, but defensive) — plain consonant.
                    inputConsonant(cho)
                }
            } else {
                if let v = landingVowel {
                    inputConsonant(cho)
                    inputVowel(v)
                } else if let content = KeyboardMetrics.keyContent(at: cell.row, column: cell.column, isSymbolMode: false) {
                    // Landed on a non-vowel cell (side symbol, backspace).
                    switch content {
                    case .symbol(let s):     inputSymbol(s)
                    case .backspace:         deleteBackward()
                    case .consonant(let c):
                        // Landed on another consonant cell with no vowel
                        // detected en-route. Commit C + (its vowel) so the
                        // user still gets a syllable for that target.
                        // (vowelFor must have returned nil above, meaning
                        // this is a rare edge — but safe fallback.)
                        if let v = KeyboardMetrics.vowelFor(row: cell.row, column: cell.column) {
                            inputConsonant(cho)
                            inputVowel(v)
                            _ = c
                        } else {
                            inputConsonant(cho)
                        }
                    default: break
                    }
                }
            }
        case .batchim(_, let cho, let jung):
            // Released on a consonant cell -> C + V + batchim.
            if let bat = consonantAt(row: cell.row, column: cell.column) {
                inputConsonant(cho)
                inputVowel(jung)
                inputConsonant(bat)
            } else if let v = KeyboardMetrics.vowelFor(row: cell.row, column: cell.column) {
                // Released back on a vowel slot — commit C + (new) V.
                inputConsonant(cho)
                inputVowel(v)
            } else {
                // Released on a symbol cell — commit just C + V.
                inputConsonant(cho)
                inputVowel(jung)
            }
        }

        resetGestureState()
    }

    /// Hit-test a point (in the keyboardGrid coordinate space) against the
    /// (now-static) koreanLayout. Returns the (row, column) of the cell
    /// under the point, or nil if outside the grid.
    private func cell(at point: CGPoint) -> (row: Int, column: Int)? {
        guard let center = gridCenterKeyWidth,
              let kh = gridKeyHeight else { return nil }
        let spacing = KeyboardMetrics.keySpacing

        // Identify which row the point falls in (rows are uniform height).
        var y: CGFloat = 0
        var row = -1
        for r in 0..<KeyboardMetrics.gridRows {
            let top = y
            let bottom = y + kh
            if point.y >= top - spacing / 2 && point.y < bottom + spacing / 2 {
                row = r
                break
            }
            y = bottom + spacing
        }
        if row < 0 { return nil }

        // Walk the columns of that row, summing widths, to find the column.
        let columnCount = KeyboardMetrics.columnCount(for: row, isSymbolMode: isSymbolMode)
        var x: CGFloat = 0
        for col in 0..<columnCount {
            let w = KeyboardMetrics.keyWidth(for: col, row: row, centerKeyWidth: center)
            if point.x >= x - spacing / 2 && point.x < x + w + spacing / 2 {
                return (row, col)
            }
            x += w + spacing
        }
        return nil
    }

    private func consonantAt(row: Int, column: Int) -> Choseong? {
        if let c = KeyboardMetrics.keyContent(at: row, column: column, isSymbolMode: false),
           case .consonant(let cho) = c {
            return cho
        }
        return nil
    }

    private func handleSymbolModeTap(row: Int, column: Int) {
        guard let content = KeyboardMetrics.keyContent(at: row, column: column, isSymbolMode: true) else { return }

        switch content {
        case .symbol(let symbol):
            inputSymbol(symbol)
        case .backspace:
            deleteBackward()
        case .consonant, .vowel, .hidden:
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
        case .vowel, .hidden:
            // .vowel/.hidden never appear in koreanLayout; popup-mode releases
            // are handled by gestureEnded(at:) before reaching this code path.
            break
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
        gridTotalWidth = nil
        gridCenterKeyWidth = nil
        gridKeyHeight = nil
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
