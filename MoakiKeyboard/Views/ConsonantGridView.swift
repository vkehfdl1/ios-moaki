import SwiftUI

struct KeyGridView: View {
    let centerKeyWidth: CGFloat
    let keyHeight: CGFloat
    let totalWidth: CGFloat
    let isSymbolMode: Bool
    /// Vowel-popup phase (see PopupPhase). When non-.consonant, the grid
    /// renders the vowel popup layout instead of koreanLayout.
    var popupPhase: PopupPhase = .idle
    /// Cell under the finger during popup-mode SELECTING. Drives the live
    /// inverted-cell highlight. nil when not selecting or off-grid.
    var highlightedSlot: (row: Int, column: Int)? = nil
    let activeKey: (row: Int, column: Int)?
    let previewVowel: Jungseong?
    var hintOptions: [VowelOption] = []
    var hintAnchor: CGPoint? = nil
    let onConsonantTap: (Choseong) -> Void
    let onSymbolTap: (String) -> Void
    let onBackspacePressStart: () -> Void
    let onBackspacePressEnd: () -> Void
    let onLongPressNumber: (String) -> Void
    let onGestureStart: (Int, Int, CGPoint) -> Void
    let onGestureMove: (CGPoint) -> Void
    let onGestureEnd: (Int, Int) -> Void

    /// In the new STATIC popup design the grid never morphs — these
    /// properties were used by the old cascade reflow and are gone.
    /// `vowelHintsVisible` brightens the per-key vowel hint labels while
    /// the user is mid-gesture (SELECTING phase).
    private var vowelHintsVisible: Bool {
        // Show hints any time popup mode is enabled (gray hints always
        // visible; the SELECTING phase makes them brighter via KeyView's
        // own logic). We keep the prop simple: feature gated by setting.
        return KeyboardSettings.shared.useVowelPopupMode
    }

    private var isInSelecting: Bool {
        if case .selecting = popupPhase { return true }
        return false
    }

    /// Origin (row, column) of the active SELECTING popup, or nil if not selecting.
    private var selectingOrigin: (row: Int, column: Int)? {
        if case .selecting(let origin, _, _, _) = popupPhase {
            return origin
        }
        return nil
    }

    /// Directional adjacent cells (post-clip) for the current SELECTING
    /// source. Empty when not selecting.
    private var directionalCells: [(row: Int, column: Int, vowel: Jungseong, direction: GestureDirection)] {
        guard let o = selectingOrigin else { return [] }
        return KeyboardMetrics.directionalVowels(around: o.row, column: o.column)
    }

    /// Look up the directional vowel for (row, column) when selecting.
    private func directionalVowel(at row: Int, column: Int) -> Jungseong? {
        return directionalCells.first(where: { $0.row == row && $0.column == column })?.vowel
    }

    var body: some View {
        VStack(spacing: KeyboardMetrics.keySpacing) {
            ForEach(0..<KeyboardMetrics.gridRows, id: \.self) { row in
                HStack(spacing: KeyboardMetrics.keySpacing) {
                    let columnCount = KeyboardMetrics.columnCount(for: row, isSymbolMode: isSymbolMode)
                    ForEach(0..<columnCount, id: \.self) { column in
                        let content: KeyContent = KeyboardMetrics.keyContent(at: row, column: column, isSymbolMode: isSymbolMode) ?? .symbol("")
                        let isActive = activeKey?.row == row && activeKey?.column == column
                        let longPressNumber = isSymbolMode ? nil : KeyboardMetrics.longPressNumber(at: row, column: column)
                        let width = KeyboardMetrics.keyWidth(
                            for: column,
                            row: row,
                            centerKeyWidth: centerKeyWidth
                        )
                        // Channel B — fixed-vowel hint (small gray) for the 15
                        // closest-to-center consonant slots. Suppressed in
                        // symbol mode.
                        let fixedHint: Jungseong? = (!isSymbolMode && vowelHintsVisible)
                            ? KeyboardMetrics.fixedVowelHint(row: row, column: column)
                            : nil
                        // Channel A — directional overlay during SELECTING.
                        // The 6 adjacent cells (after clipping) display the
                        // basic vowel large/prominent on top of whatever was
                        // there. The source cell is hidden (finger covers it).
                        let isOrigin = (selectingOrigin?.row == row && selectingOrigin?.column == column)
                        let dirVowel: Jungseong? = directionalVowel(at: row, column: column)
                        // Live slide highlight: only meaningful in popup
                        // SELECTING phase, and never on the (hidden) source.
                        let isHighlightedCell = isInSelecting
                            && !isOrigin
                            && highlightedSlot?.row == row
                            && highlightedSlot?.column == column
                        KeyView(
                            content: content,
                            keySize: CGSize(width: width, height: keyHeight),
                            isPressed: isActive,
                            previewVowel: isActive ? previewVowel : nil,
                            vowelHint: fixedHint,
                            isInSelecting: isInSelecting,
                            reservesHintSpace: !isSymbolMode && vowelHintsVisible,
                            directionalOverlay: dirVowel,
                            isSlideHighlighted: isHighlightedCell,
                            hideContent: isOrigin,
                            hintOptions: isActive ? hintOptions : [],
                            hintAnchor: isActive ? hintAnchor : nil,
                            longPressNumber: longPressNumber,
                            onLongPress: { number in
                                onLongPressNumber(number)
                            },
                            onBackspacePressStart: {
                                guard case .backspace = content else { return }
                                onBackspacePressStart()
                            },
                            onBackspacePressEnd: {
                                guard case .backspace = content else { return }
                                onBackspacePressEnd()
                            },
                            onGestureStart: { point in
                                onGestureStart(row, column, point)
                            },
                            onGestureMove: { point in
                                onGestureMove(point)
                            },
                            onGestureEnd: {
                                onGestureEnd(row, column)
                            }
                        )
                        .zIndex(isActive ? 2 : (dirVowel != nil ? 1 : 0))
                    }
                }
                .zIndex(activeKey?.row == row ? 1 : 0)
            }
        }
        // Named coordinate space lets the per-key DragGesture report finger
        // positions relative to the whole grid, so the ViewModel can hit-test
        // against any cell during popup-mode drags.
        .coordinateSpace(name: KeyGridView.gridCoordinateSpace)
    }

    static let gridCoordinateSpace = "moakiKeyboardGrid"
}

// Legacy alias for compatibility
typealias ConsonantGridView = KeyGridView

#Preview {
    VStack(spacing: 20) {
        Text("Korean Mode")
            .font(.headline)
        KeyGridView(
            centerKeyWidth: 45,
            keyHeight: 50,
            totalWidth: 350,
            isSymbolMode: false,
            activeKey: (1, 2),
            previewVowel: .ㅏ,
            onConsonantTap: { _ in },
            onSymbolTap: { _ in },
            onBackspacePressStart: {},
            onBackspacePressEnd: {},
            onLongPressNumber: { _ in },
            onGestureStart: { _, _, _ in },
            onGestureMove: { _ in },
            onGestureEnd: { _, _ in }
        )

        Text("Symbol Mode")
            .font(.headline)
        KeyGridView(
            centerKeyWidth: 45,
            keyHeight: 50,
            totalWidth: 350,
            isSymbolMode: true,
            activeKey: nil,
            previewVowel: nil,
            onConsonantTap: { _ in },
            onSymbolTap: { _ in },
            onBackspacePressStart: {},
            onBackspacePressEnd: {},
            onLongPressNumber: { _ in },
            onGestureStart: { _, _, _ in },
            onGestureMove: { _ in },
            onGestureEnd: { _, _ in }
        )
    }
    .padding()
    .background(Color(.systemGray6))
}
