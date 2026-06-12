import Foundation

/// 자주 쓰는 문구(계좌·주소 등) 상용어 저장소. 최대 `maxCount`개.
/// 키보드 익스텐션 자체 UserDefaults에 저장 — App Group 불필요.
final class SnippetStore {
    static let shared = SnippetStore()

    private let defaults = UserDefaults.standard
    private let key = "snippets"
    let maxCount = 10

    private(set) var all: [String]

    private init() {
        all = defaults.stringArray(forKey: key) ?? []
    }

    @discardableResult
    func add(_ raw: String) -> Bool {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty, !all.contains(s), all.count < maxCount else { return false }
        all.append(s)
        persist()
        return true
    }

    func remove(at index: Int) {
        guard all.indices.contains(index) else { return }
        all.remove(at: index)
        persist()
    }

    private func persist() {
        defaults.set(all, forKey: key)
    }
}
