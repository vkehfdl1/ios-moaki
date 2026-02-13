import SwiftUI

struct KeyGridView: View {
    let centerKeyWidth: CGFloat
    let keyHeight: CGFloat
    let totalWidth: CGFloat
    let isSymbolMode: Bool
    let activeKey: (row: Int, column: Int)?
    let previewVowel: Jungseong?
    let onConsonantTap: (Choseong) -> Void
    let onSymbolTap: (String) -> Void
    let onBackspace: () -> Void
    let onLongPressNumber: (String) -> Void
    let onGestureStart: (Int, Int, CGPoint) -> Void
    let onGestureMove: (CGPoint) -> Void
    let onGestureEnd: (Int, Int) -> Void

    var body: some View {
        VStack(spacing: KeyboardMetrics.keySpacing) {
            ForEach(0..<KeyboardMetrics.gridRows, id: \.self) { row in
                HStack(spacing: KeyboardMetrics.keySpacing) {
                    let columnCount = KeyboardMetrics.columnCount(for: row, isSymbolMode: isSymbolMode)

                    ForEach(0..<columnCount, id: \.self) { column in
                        let content = KeyboardMetrics.keyContent(at: row, column: column, isSymbolMode: isSymbolMode)
                        let isActive = activeKey?.row == row && activeKey?.column == column
                        let longPressNumber = isSymbolMode ? nil : KeyboardMetrics.longPressNumber(at: row, column: column)
                        let width = KeyboardMetrics.keyWidth(
                            for: column,
                            row: row,
                            centerKeyWidth: centerKeyWidth,
                            totalWidth: totalWidth,
                            isSymbolMode: isSymbolMode
                        )

                        KeyView(
                            content: content ?? .symbol(""),
                            keySize: CGSize(width: width, height: keyHeight),
                            isPressed: isActive,
                            previewVowel: isActive ? previewVowel : nil,
                            longPressNumber: longPressNumber,
                            onTap: {
                                handleTap(content: content)
                            },
                            onLongPress: { number in
                                onLongPressNumber(number)
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
                    }
                }
            }
        }
    }

    private func handleTap(content: KeyContent?) {
        guard let content = content else { return }

        switch content {
        case .consonant(let choseong):
            onConsonantTap(choseong)
        case .symbol(let symbol):
            onSymbolTap(symbol)
        case .backspace:
            onBackspace()
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
            isSymbolMode: false,
            activeKey: (1, 2),
            previewVowel: .ㅏ,
            onConsonantTap: { _ in },
            onSymbolTap: { _ in },
            onBackspace: {},
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
            onBackspace: {},
            onLongPressNumber: { _ in },
            onGestureStart: { _, _, _ in },
            onGestureMove: { _ in },
            onGestureEnd: { _, _ in }
        )
    }
    .padding()
    .background(Color(.systemGray6))
}
