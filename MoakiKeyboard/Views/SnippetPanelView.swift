import SwiftUI

/// 상용어 목록 패널. 키보드 영역 안에 오버레이로 띄운다
/// (키보드 익스텐션은 모달 `.sheet`가 잘 안 떠서).
struct SnippetPanelView: View {
    let snippets: [String]
    let maxCount: Int
    let onInsert: (String) -> Void
    let onAdd: () -> Void
    let onRemove: (Int) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Text("상용어")
                    .font(.headline)
                Spacer()
                Button(action: onAdd) {
                    Label("현재 줄 추가", systemImage: "plus")
                        .font(.system(size: 14))
                }
                .disabled(snippets.count >= maxCount)
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 10)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            if snippets.isEmpty {
                Spacer()
                Text("등록된 상용어가 없어요.\n입력창에 문구(계좌·주소 등)를 친 뒤\n'현재 줄 추가'를 누르세요.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(snippets.enumerated()), id: \.offset) { index, snippet in
                            HStack(spacing: 12) {
                                Button(action: { onInsert(snippet) }) {
                                    Text(snippet)
                                        .font(.system(size: 15))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                Button(action: { onRemove(index) }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 15))
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            Divider()
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
}
