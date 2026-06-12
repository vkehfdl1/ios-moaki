import SwiftUI

struct KeyGridView: View {
    let centerKeyWidth: CGFloat
    let keyHeight: CGFloat
    let totalWidth: CGFloat
    let mode: KeyboardMode
    let activeKey: (row: Int, column: Int)?
    let previewVowel: Jungseong?
    var hintOptions: [VowelOption] = []
    var hintAnchor: CGPoint? = nil
    var isShiftEnabled: Bool = false  // English: forwarded to each key for label/icon state
    let onConsonantTap: (Choseong) -> Void
    let onSymbolTap: (String) -> Void
    let onBackspacePressStart: () -> Void
    let onBackspacePressEnd: () -> Void
    let onLongPressNumber: (String) -> Void
    let onGestureStart: (Int, Int, CGPoint) -> Void
    let onGestureMove: (CGPoint) -> Void
    let onGestureEnd: (Int, Int) -> Void

    var body: some View {
        // English mode uses a uniform key width; Korean/symbol use the center/side split.
        let unitWidth = mode == .english
            ? KeyboardMetrics.englishKeyWidth(for: totalWidth)
            : centerKeyWidth

        VStack(spacing: KeyboardMetrics.keySpacing) {
            // Iterate the active layout's row count — English is 3 rows, Korean/symbol are 4.
            ForEach(0..<KeyboardMetrics.rowCount(for: mode), id: \.self) { row in
                HStack(spacing: KeyboardMetrics.keySpacing) {
                    let columnCount = KeyboardMetrics.columnCount(for: row, mode: mode)

                    ForEach(0..<columnCount, id: \.self) { column in
                        let content = KeyboardMetrics.keyContent(at: row, column: column, mode: mode)
                        let isActive = activeKey?.row == row && activeKey?.column == column
                        let longPressNumber = mode == .korean ? KeyboardMetrics.longPressNumber(at: row, column: column) : nil
                        let width = KeyboardMetrics.keyWidth(
                            for: column,
                            row: row,
                            centerKeyWidth: unitWidth,
                            mode: mode
                        )

                        KeyView(
                            content: content ?? .symbol(""),
                            keySize: CGSize(width: width, height: keyHeight),
                            isPressed: isActive,
                            previewVowel: isActive ? previewVowel : nil,
                            hintOptions: isActive ? hintOptions : [],
                            hintAnchor: isActive ? hintAnchor : nil,
                            longPressNumber: longPressNumber,
                            isShiftEnabled: mode == .english && isShiftEnabled,
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
    }
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
            mode: .korean,
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

        Text("English Mode")
            .font(.headline)
        KeyGridView(
            centerKeyWidth: 45,
            keyHeight: 50,
            totalWidth: 350,
            mode: .english,
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
