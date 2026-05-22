import Foundation

/// 사용자가 입력한 단어를 빈도와 함께 저장하는 개인 사전.
/// 키보드 익스텐션은 메모리 제약이 있어 상위 빈도 `maxWords`개만 유지한다.
final class WordStore {
    static let shared = WordStore()

    private let defaults = UserDefaults.standard
    private let storageKey = "learnedWords"
    private let maxWords = 3000
    private let minWordLength = 2          // 한 글자는 노이즈라 학습 제외

    private var counts: [String: Int]

    private init() {
        counts = (defaults.dictionary(forKey: storageKey) as? [String: Int]) ?? [:]
    }

    /// 확정된 단어 학습 (빈도 +1). 순수 한글 단어만 받는다.
    func record(_ rawWord: String) {
        let word = rawWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard word.count >= minWordLength, Self.isHangulWord(word) else { return }
        counts[word, default: 0] += 1
        if counts.count > maxWords { prune() }
        persist()
    }

    /// `prefix`로 시작하는 단어를 빈도순으로 반환 (입력값과 동일한 단어는 제외).
    func suggestions(prefix: String, limit: Int = 3) -> [String] {
        let p = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !p.isEmpty else { return [] }
        return counts
            .filter { $0.key != p && $0.key.hasPrefix(p) }
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }

    private static func isHangulWord(_ s: String) -> Bool {
        !s.isEmpty && s.unicodeScalars.allSatisfy { (0xAC00...0xD7A3).contains($0.value) }
    }

    private func prune() {
        let kept = counts.sorted { $0.value > $1.value }.prefix(maxWords)
        counts = Dictionary(uniqueKeysWithValues: kept.map { ($0.key, $0.value) })
    }

    private func persist() {
        defaults.set(counts, forKey: storageKey)
    }
}
