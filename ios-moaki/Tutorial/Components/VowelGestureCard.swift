import SwiftUI

struct VowelGestureCard: View {
    let gesture: VowelGesture

    var body: some View {
        VStack(spacing: 6) {
            Text(gesture.vowel)
                .font(.system(size: 28, weight: .bold))

            HStack(spacing: 4) {
                GestureArrowDiagram(directions: gesture.directions)
                if let alt = gesture.altDirections {
                    Text("/")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    GestureArrowDiagram(directions: alt)
                }
            }

            VStack(spacing: 2) {
                Text(gesture.label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let altLabel = gesture.altLabel {
                    Text("또는 \(altLabel)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}
