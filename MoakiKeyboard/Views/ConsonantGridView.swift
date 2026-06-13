import SwiftUI

struct KeyGridView: View {
    let centerKeyWidth: CGFloat
    let keyHeight: CGFloat
    let totalWidth: CGFloat
    let isSymbolMode: Bool
    /// Vowel-popup phase (see PopupPhase). When non-.consonant, the grid
    /// renders the vowel popup layout instead of koreanLayout.
    var popupPhase: PopupPhase = .consonant
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

    /// True when the grid is showing the vowel popup layout. In .batchim
    /// phase we show koreanLayout (consonants) so the user can pick a batchim.
    private var isVowelPopup: Bool {
        if case .vowel = popupPhase { return true }
        return false
    }

    /// (row, column) of the originating consonant when in popup mode.
    /// Its slot is rendered as .hidden in the .vowel phase so the user's
    /// finger isn't covered by their own touched key. In .batchim phase the
    /// originating consonant comes back (it'll be selected if the user
    /// releases on it).
    private var popupOrigin: (row: Int, column: Int)? {
        switch popupPhase {
        case .consonant: return nil
        case .vowel(let o, _): return o
        case .batchim: return nil
        }
    }

    var body: some View {
        VStack(spacing: KeyboardMetrics.keySpacing) {
            ForEach(0..<KeyboardMetrics.gridRows, id: \.self) { row in
                HStack(spacing: KeyboardMetrics.keySpacing) {
                    let columnCount = KeyboardMetrics.columnCount(for: row, isSymbolMode: isSymbolMode, isVowelPopup: isVowelPopup)
                    ForEach(0..<columnCount, id: \.self) { column in
                        let rawContent = KeyboardMetrics.keyContent(at: row, column: column, isSymbolMode: isSymbolMode, isVowelPopup: isVowelPopup)
                        // Hide the consonant cell that originated the popup so the
                        // finger isn't covered by the morphed-away key.
                        let content: KeyContent = {
                            if let origin = popupOrigin, origin.row == row && origin.column == column {
                                return .hidden
                            }
                            return rawContent ?? .symbol("")
                        }()
                        let isActive = activeKey?.row == row && activeKey?.column == column
                        let longPressNumber = (isSymbolMode || isVowelPopup) ? nil : KeyboardMetrics.longPressNumber(at: row, column: column)
                        let width = KeyboardMetrics.keyWidth(
                            for: column,
                            row: row,
                            centerKeyWidth: centerKeyWidth,
                            isVowelPopup: isVowelPopup
                        )

                        KeyView(
                            content: content,
                            keySize: CGSize(width: width, height: keyHeight),
                            isPressed: isActive,
                            previewVowel: isActive ? previewVowel : nil,
                            hintOptions: (isActive && !isVowelPopup) ? hintOptions : [],
                            hintAnchor: (isActive && !isVowelPopup) ? hintAnchor : nil,
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
                        .zIndex(isActive ? 1 : 0)
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
