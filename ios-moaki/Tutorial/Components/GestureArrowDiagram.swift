import SwiftUI

struct GestureArrowDiagram: View {
    let directions: [String]

    private static let sfSymbolMap: [String: String] = [
        "→": "arrow.right",
        "←": "arrow.left",
        "↑": "arrow.up",
        "↓": "arrow.down",
        "↗": "arrow.up.right",
        "↘": "arrow.down.right",
        "↖": "arrow.up.left",
        "↙": "arrow.down.left",
    ]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(directions.enumerated()), id: \.offset) { _, direction in
                Image(systemName: Self.sfSymbolMap[direction] ?? "questionmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
            }
        }
    }
}
