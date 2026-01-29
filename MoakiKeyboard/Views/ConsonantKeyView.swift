import SwiftUI

struct KeyView: View {
    let content: KeyContent
    let keySize: CGSize
    let isPressed: Bool
    let previewVowel: Jungseong?
    let longPressNumber: String?
    let onTap: () -> Void
    let onLongPress: ((String) -> Void)?
    let onGestureStart: (CGPoint) -> Void
    let onGestureMove: (CGPoint) -> Void
    let onGestureEnd: () -> Void

    @State private var isHighlighted = false
    @State private var showNumberPopup = false
    @State private var longPressTimer: Timer?

    var body: some View {
        ZStack {
            // Key background
            RoundedRectangle(cornerRadius: KeyboardMetrics.keyCornerRadius)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.2), radius: isPressed ? 0 : 1, y: isPressed ? 0 : 1)

            // Key label
            keyLabel
        }
        .frame(width: keySize.width, height: keySize.height)
        .overlay(numberPopupOverlay, alignment: .top)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isHighlighted {
                        isHighlighted = true
                        onGestureStart(value.startLocation)
                        startLongPressTimer()
                    }

                    // Cancel long press if user moved significantly (for consonant gesture)
                    let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    if distance > KeyboardMetrics.gestureThreshold {
                        cancelLongPressTimer()
                    }

                    onGestureMove(value.location)
                }
                .onEnded { _ in
                    isHighlighted = false
                    cancelLongPressTimer()
                    hideNumberPopup()
                    onGestureEnd()
                }
        )
    }

    @ViewBuilder
    private var keyLabel: some View {
        switch content {
        case .consonant(let consonant):
            VStack(spacing: 2) {
                Text(String(consonant.compatibilityCharacter))
                    .font(.system(size: keySize.height * 0.4, weight: .medium))
                    .foregroundColor(textColor)

                // Show preview vowel when dragging
                if let vowel = previewVowel {
                    Text(String(vowel.compatibilityCharacter))
                        .font(.system(size: keySize.height * 0.25))
                        .foregroundColor(.blue)
                }
            }

        case .symbol(let symbol):
            Text(symbol)
                .font(.system(size: keySize.height * 0.4, weight: .medium))
                .foregroundColor(textColor)

        case .backspace:
            Image(systemName: "delete.left")
                .font(.system(size: keySize.height * 0.35))
                .foregroundColor(textColor)
        }
    }

    @ViewBuilder
    private var numberPopupOverlay: some View {
        if showNumberPopup, let number = longPressNumber {
            Text(number)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                )
                .offset(y: -keySize.height * 0.8)
        }
    }

    private var backgroundColor: Color {
        switch content {
        case .backspace:
            return isPressed || isHighlighted ? Color(.systemGray3) : Color(.systemGray5)
        case .symbol:
            return isPressed || isHighlighted ? Color(.systemGray3) : Color(.systemGray5)
        case .consonant:
            return isPressed || isHighlighted ? Color(.systemGray4) : Color(.secondarySystemBackground)
        }
    }

    private var textColor: Color {
        return .primary
    }

    private func startLongPressTimer() {
        guard longPressNumber != nil else { return }

        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            showNumberPopup = true
            if let number = longPressNumber {
                onLongPress?(number)
            }
        }
    }

    private func cancelLongPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = nil
    }

    private func hideNumberPopup() {
        showNumberPopup = false
    }
}

// Legacy alias for compatibility
typealias ConsonantKeyView = KeyView

#Preview {
    HStack {
        KeyView(
            content: .consonant(.ㄱ),
            keySize: CGSize(width: 50, height: 50),
            isPressed: false,
            previewVowel: nil,
            longPressNumber: "4",
            onTap: {},
            onLongPress: { _ in },
            onGestureStart: { _ in },
            onGestureMove: { _ in },
            onGestureEnd: {}
        )

        KeyView(
            content: .consonant(.ㄴ),
            keySize: CGSize(width: 50, height: 50),
            isPressed: true,
            previewVowel: .ㅏ,
            longPressNumber: "7",
            onTap: {},
            onLongPress: { _ in },
            onGestureStart: { _ in },
            onGestureMove: { _ in },
            onGestureEnd: {}
        )

        KeyView(
            content: .symbol("!"),
            keySize: CGSize(width: 50, height: 50),
            isPressed: false,
            previewVowel: nil,
            longPressNumber: nil,
            onTap: {},
            onLongPress: nil,
            onGestureStart: { _ in },
            onGestureMove: { _ in },
            onGestureEnd: {}
        )

        KeyView(
            content: .backspace,
            keySize: CGSize(width: 50, height: 50),
            isPressed: false,
            previewVowel: nil,
            longPressNumber: nil,
            onTap: {},
            onLongPress: nil,
            onGestureStart: { _ in },
            onGestureMove: { _ in },
            onGestureEnd: {}
        )
    }
    .padding()
    .background(Color(.systemGray6))
}
