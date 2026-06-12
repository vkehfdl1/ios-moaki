import SwiftUI

struct FunctionRowView: View {
    let totalWidth: CGFloat
    let mode: KeyboardMode
    let onSwitchMode: (KeyboardMode) -> Void
    let onCommaPressed: () -> Void
    let onSpacePressed: () -> Void
    let onReturnPressed: () -> Void
    let onSnippetPressed: () -> Void

    private let spacing: CGFloat = KeyboardMetrics.keySpacing
    private let height: CGFloat = KeyboardMetrics.functionRowHeight

    // Each button is labeled with the mode it switches TO.
    private var languageTarget: (label: String, mode: KeyboardMode) {
        mode == .korean ? ("ABC", .english) : ("한글", .korean)
    }

    private var symbolTarget: (label: String, mode: KeyboardMode) {
        mode == .symbol ? ("ABC", .english) : ("123", .symbol)
    }

    var body: some View {
        HStack(spacing: spacing) {
            // Language toggle (한글 ↔ ABC)
            FunctionKeyView(
                content: AnyView(
                    Text(languageTarget.label)
                        .font(.system(size: 15, weight: .medium))
                ),
                width: languageWidth,
                height: height,
                action: { onSwitchMode(languageTarget.mode) }
            )

            // Symbol/number toggle (123, or ABC when already in symbol mode)
            FunctionKeyView(
                content: AnyView(
                    Text(symbolTarget.label)
                        .font(.system(size: 15, weight: .medium))
                ),
                width: symbolWidth,
                height: height,
                action: { onSwitchMode(symbolTarget.mode) }
            )

            // Comma key (left of space)
            FunctionKeyView(
                content: AnyView(
                    Text(",")
                        .font(.system(size: 20))
                ),
                width: commaWidth,
                height: height,
                action: onCommaPressed
            )

            // Snippet (상용어) — 문서 아이콘, 스페이스 옆
            FunctionKeyView(
                content: AnyView(
                    Image(systemName: "doc.text")
                        .font(.system(size: 18))
                ),
                width: snippetWidth,
                height: height,
                action: onSnippetPressed
            )

            // Space bar
            FunctionKeyView(
                content: AnyView(
                    Text("space")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                ),
                width: spaceWidth,
                height: height,
                action: onSpacePressed
            )

            // Return button
            FunctionKeyView(
                content: AnyView(
                    Image(systemName: "return")
                        .font(.system(size: 20))
                ),
                width: returnWidth,
                height: height,
                action: onReturnPressed
            )
        }
    }

    private var returnWidth: CGFloat {
        // Match backspace width: sideWidth + centerKeyWidth + spacing
        let centerKeyWidth = KeyboardMetrics.centerKeyWidth(for: totalWidth)
        let sideWidth = centerKeyWidth * KeyboardMetrics.symbolWidthRatio
        return sideWidth + centerKeyWidth + KeyboardMetrics.keySpacing
    }

    private var availableWidthWithoutReturn: CGFloat {
        totalWidth - returnWidth - spacing * 7  // 7 gaps for 6 buttons + edges
    }

    private var languageWidth: CGFloat {
        availableWidthWithoutReturn * 0.14
    }

    private var symbolWidth: CGFloat {
        availableWidthWithoutReturn * 0.12
    }

    private var commaWidth: CGFloat {
        availableWidthWithoutReturn * 0.12
    }

    private var snippetWidth: CGFloat {
        availableWidthWithoutReturn * 0.13
    }

    private var spaceWidth: CGFloat {
        availableWidthWithoutReturn * 0.49
    }
}

struct FunctionKeyView: View {
    let content: AnyView
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        content
            .frame(width: width, height: height)
            .background(
                RoundedRectangle(cornerRadius: KeyboardMetrics.keyCornerRadius)
                    .fill(isPressed ? Color(.systemGray5) : Color(.systemBackground))
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        action()
                    }
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        ForEach([KeyboardMode.korean, .english, .symbol], id: \.self) { mode in
            FunctionRowView(
                totalWidth: 350,
                mode: mode,
                onSwitchMode: { print("Switch to \($0)") },
                onCommaPressed: { print("Comma") },
                onSpacePressed: { print("Space") },
                onReturnPressed: { print("Return") },
                onSnippetPressed: { print("Snippet") }
            )
        }
    }
    .padding()
    .background(Color(.systemGray6))
}
