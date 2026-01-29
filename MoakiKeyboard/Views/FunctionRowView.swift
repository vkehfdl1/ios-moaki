import SwiftUI

struct FunctionRowView: View {
    let totalWidth: CGFloat
    let isSymbolMode: Bool
    let onToggleModePressed: () -> Void
    let onCommaPressed: () -> Void
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
                    Text(",")
                        .font(.system(size: 20))
                ),
                width: commaWidth,
                height: height,
                action: onCommaPressed
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

    private var availableWidth: CGFloat {
        totalWidth - spacing * 5  // 5 gaps for 4 buttons + edges
    }

    private var toggleWidth: CGFloat {
        availableWidth * 0.22
    }

    private var commaWidth: CGFloat {
        availableWidth * 0.10
    }

    private var spaceWidth: CGFloat {
        availableWidth * 0.33
    }

    private var returnWidth: CGFloat {
        availableWidth * 0.35
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
            onSpacePressed: { print("Space") },
            onReturnPressed: { print("Return") }
        )
    }
    .padding()
    .background(Color(.systemGray6))
}
