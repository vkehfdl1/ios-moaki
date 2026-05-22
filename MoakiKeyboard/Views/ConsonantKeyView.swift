import SwiftUI

struct KeyView: View {
    let content: KeyContent
    let keySize: CGSize
    let isPressed: Bool
    let previewVowel: Jungseong?
    var hintOptions: [VowelOption] = []
    var hintAnchor: CGPoint? = nil
    let longPressNumber: String?
    let onLongPress: ((String) -> Void)?
    let onBackspacePressStart: (() -> Void)?
    let onBackspacePressEnd: (() -> Void)?
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
        .overlay(vowelHintsOverlay)
        .overlay(numberPopupOverlay, alignment: .top)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isHighlighted {
                        isHighlighted = true
                        if isBackspaceKey {
                            onBackspacePressStart?()
                        } else {
                            onGestureStart(value.startLocation)
                            startLongPressTimer()
                        }
                    }

                    guard !isBackspaceKey else { return }

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
                    if isBackspaceKey {
                        onBackspacePressEnd?()
                    } else {
                        onGestureEnd()
                    }
                }
        )
        .onDisappear {
            if isHighlighted && isBackspaceKey {
                onBackspacePressEnd?()
            }
            cancelLongPressTimer()
            isHighlighted = false
            showNumberPopup = false
        }
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

    // MARK: - Vowel direction hints (composed syllables; progressive while dragging)

    @ViewBuilder
    private var vowelHintsOverlay: some View {
        if isPressed, case .consonant(let cho) = content, !hintOptions.isEmpty {
            let cellW = keySize.width + KeyboardMetrics.keySpacing
            let cellH = keySize.height + KeyboardMetrics.keySpacing
            let center = CGPoint(x: keySize.width / 2, y: keySize.height / 2)
            // Anchor on the grid cell currently under the finger (the consonant key itself
            // until a stroke moves away), snapped cell-to-cell so it never drifts. Each hint
            // then sits one cell over in its next-stroke direction — exactly where the finger
            // must move to select that vowel — so position matches the gesture logic.
            let raw = hintAnchor ?? center
            let col = ((raw.x - center.x) / cellW).rounded()
            let row = ((raw.y - center.y) / cellH).rounded()
            let anchor = CGPoint(x: center.x + col * cellW, y: center.y + row * cellH)
            ZStack {
                ForEach(hintOptions, id: \.direction) { option in
                    let v = option.direction.unitVector
                    Text(String(HangulConstants.composeSyllable(choseong: cho, jungseong: option.vowel)))
                        .font(.system(size: keySize.height * 0.4, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: keySize.width, height: keySize.height)
                        .background(
                            RoundedRectangle(cornerRadius: KeyboardMetrics.keyCornerRadius)
                                .fill(Color(red: 0.282, green: 0.651, blue: 0.635).opacity(0.92))
                                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                        )
                        .position(x: anchor.x + v.dx * cellW,
                                  y: anchor.y + v.dy * cellH)
                }
            }
            .allowsHitTesting(false)
        }
    }

    private var backgroundColor: Color {
        switch content {
        case .backspace:
            return isPressed || isHighlighted ? Color(.systemGray4) : Color(.systemGray6)
        case .symbol:
            return isPressed || isHighlighted ? Color(.systemGray4) : Color(.systemGray6)
        case .consonant:
            return isPressed || isHighlighted ? Color(.systemGray5) : Color(.systemBackground)
        }
    }

    private var textColor: Color {
        return .primary
    }

    private var isBackspaceKey: Bool {
        if case .backspace = content {
            return true
        }
        return false
    }

    private func startLongPressTimer() {
        guard KeyboardSettings.shared.enableLongPressNumber, longPressNumber != nil else { return }

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
            onLongPress: { _ in },
            onBackspacePressStart: nil,
            onBackspacePressEnd: nil,
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
            onLongPress: { _ in },
            onBackspacePressStart: nil,
            onBackspacePressEnd: nil,
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
            onLongPress: nil,
            onBackspacePressStart: nil,
            onBackspacePressEnd: nil,
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
            onLongPress: nil,
            onBackspacePressStart: {},
            onBackspacePressEnd: {},
            onGestureStart: { _ in },
            onGestureMove: { _ in },
            onGestureEnd: {}
        )
    }
    .padding()
    .background(Color(.systemGray6))
}
