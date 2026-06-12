import SwiftUI

/// 단어 예측 후보 바. 키보드 최상단에 가로로, 빈도순 후보를 보여준다.
/// 후보가 없어도 높이는 유지해 레이아웃이 흔들리지 않게 한다.
struct SuggestionBarView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 0) {
            if suggestions.isEmpty {
                Spacer()
            } else {
                ForEach(Array(suggestions.enumerated()), id: \.offset) { index, word in
                    if index > 0 {
                        Divider().frame(height: 22)
                    }
                    Button(action: { onSelect(word) }) {
                        Text(word)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: KeyboardMetrics.suggestionBarHeight)
    }
}
