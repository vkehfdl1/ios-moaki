import Foundation

class VowelResolver {
    private let patternTrie = VowelPattern.patternTrie

    struct Resolution {
        let vowel: Jungseong?
        let hasMoreMatches: Bool
    }

    // 왼쪽 대각선만 수직 방향으로 정규화
    // ↖ (upLeft) → ↑ (up): ㅗ
    // ↙ (downLeft) → ↓ (down): ㅜ
    // 오른쪽 대각선은 그대로 유지 (↗ → ㅣ, ↘ → ㅡ)
    private func normalizeDirection(_ direction: GestureDirection) -> GestureDirection {
        switch direction {
        case .upLeft: return .up
        case .downLeft: return .down
        default: return direction
        }
    }

    private func normalizeDirections(_ directions: [GestureDirection]) -> [GestureDirection] {
        directions.map { normalizeDirection($0) }
    }

    func resolve(directions: [GestureDirection]) -> Resolution {
        guard !directions.isEmpty else {
            return Resolution(vowel: nil, hasMoreMatches: false)
        }

        let normalized = normalizeDirections(directions)
        let result = patternTrie.match(normalized)
        return Resolution(
            vowel: result.vowel,
            hasMoreMatches: result.hasLongerMatch
        )
    }

    // For real-time feedback during gesture
    func peekVowel(directions: [GestureDirection]) -> Jungseong? {
        guard !directions.isEmpty else { return nil }
        let normalized = normalizeDirections(directions)
        let result = patternTrie.match(normalized)
        return result.vowel
    }

    // Check if current directions could potentially match a vowel
    func hasPotentialMatch(directions: [GestureDirection]) -> Bool {
        guard !directions.isEmpty else { return false }
        let normalized = normalizeDirections(directions)
        let result = patternTrie.match(normalized)
        return result.vowel != nil || result.hasLongerMatch
    }
}
