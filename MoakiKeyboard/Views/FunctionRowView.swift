import SwiftUI

struct FunctionRowView: View {
    let totalWidth: CGFloat
    let isSymbolMode: Bool
    let onToggleModePressed: () -> Void
    let onCommaPressed: () -> Void
    let onBackspacePressed: () -> Void
    let onSpacePressed: () -> Void
    let onReturnPressed: () -> Void

    private let spacing: CGFloat = KeyboardMetrics.keySpacing
    private let height: CGFloat = KeyboardMetrics.functionRowHeight

    var body: some View {
        HStack(spacing: spacing) {
            // 123/한글 toggle button (replaces globe)
            FunctionKeyView(
                content: AnyView(
                    Text(isSymbolMode ? "한글" : "123")
                        .font(.system(size: 16, weight: .medium))
                ),
                width: toggleWidth,
                height: height,
                action: onToggleModePressed
            )

            // Comma key (left of space)
            FunctionKeyView(
                content: AnyView(
                    Group {
                        if isSymbolMode {
                            Image(systemName: "delete.left")
                                .font(.system(size: 18))
                        } else {
                            Text(",")
                                .font(.system(size: 20))
                        }
                    }
                ),
                width: commaWidth,
                height: height,
                action: isSymbolMode ? onBackspacePressed : onCommaPressed
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
        totalWidth - returnWidth - spacing * 5  // 5 gaps for 4 buttons + edges
    }

    private var toggleWidth: CGFloat {
        availableWidthWithoutReturn * 0.30
    }

    private var commaWidth: CGFloat {
        availableWidthWithoutReturn * 0.14
    }

    private var spaceWidth: CGFloat {
        availableWidthWithoutReturn * 0.56
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
                    .fill(isPressed ? Color(.systemGray4) : Color(.systemGray5))
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
        Text("Korean Mode")
            .font(.headline)
        FunctionRowView(
            totalWidth: 350,
            isSymbolMode: false,
            onToggleModePressed: { print("Toggle") },
            onCommaPressed: { print("Comma") },
            onBackspacePressed: { print("Backspace") },
            onSpacePressed: { print("Space") },
            onReturnPressed: { print("Return") }
        )

        Text("Symbol Mode")
            .font(.headline)
        FunctionRowView(
            totalWidth: 350,
            isSymbolMode: true,
            onToggleModePressed: { print("Toggle") },
            onCommaPressed: { print("Comma") },
            onBackspacePressed: { print("Backspace") },
            onSpacePressed: { print("Space") },
            onReturnPressed: { print("Return") }
        )
    }
    .padding()
    .background(Color(.systemGray6))
}
