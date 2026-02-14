import Foundation

class VowelResolver {
    private let patternTrie = VowelPattern.patternTrie

    struct Resolution {
        let vowel: Jungseong?
        let hasMoreMatches: Bool
    }

    func resolve(directions: [GestureDirection]) -> Resolution {
        guard !directions.isEmpty else {
            return Resolution(vowel: nil, hasMoreMatches: false)
        }

        let normalized = normalizeForMatching(directions)
        let match = patternTrie.match(normalized)
        return Resolution(vowel: match.vowel, hasMoreMatches: match.hasLongerMatch)
    }

    // For real-time feedback during gesture
    func peekVowel(directions: [GestureDirection]) -> Jungseong? {
        guard !directions.isEmpty else { return nil }
        let normalized = normalizeForMatching(directions)
        return patternTrie.match(normalized).vowel
    }

    // Check if current directions could potentially match a vowel
    func hasPotentialMatch(directions: [GestureDirection]) -> Bool {
        guard !directions.isEmpty else { return false }
        let normalized = normalizeForMatching(directions)
        let match = patternTrie.match(normalized)
        return match.vowel != nil || match.hasLongerMatch
    }

    /// Normalization rules:
    /// 1. First stroke keeps 8-direction intent, except ↖/↙ are canonicalized to ↑/↓.
    /// 2. From the second stroke onward, diagonals are mapped to a single cardinal axis.
    /// 3. Consecutive identical directions collapse into one stroke.
    private func normalizeForMatching(_ directions: [GestureDirection]) -> [GestureDirection] {
        guard !directions.isEmpty else { return [] }

        var normalized: [GestureDirection] = []
        normalized.reserveCapacity(directions.count)

        for (index, direction) in directions.enumerated() {
            let next: GestureDirection
            if index == 0 {
                next = normalizeFirstStroke(direction)
            } else {
                next = normalizeTrailingStroke(direction, previous: normalized.last)
            }

            // Treat repeated same-direction segments as one stroke.
            if normalized.last != next {
                normalized.append(next)
            }
        }

        return normalized
    }

    private func normalizeFirstStroke(_ direction: GestureDirection) -> GestureDirection {
        switch direction {
        case .upLeft:
            return .up
        case .downLeft:
            return .down
        default:
            return direction
        }
    }

    private func normalizeTrailingStroke(_ direction: GestureDirection,
                                         previous: GestureDirection?) -> GestureDirection {
        guard direction.isDiagonal else { return direction }

        guard let (vertical, horizontal) = diagonalComponents(of: direction) else {
            return direction
        }

        guard let previous else {
            return vertical
        }

        // If the previous stroke is horizontal, keep the diagonal's horizontal intent.
        if previous == .left || previous == .right {
            return horizontal
        }

        // For vertical previous strokes, choose horizontal only when the diagonal
        // shares the same vertical intent (e.g. ↑ then ↗ => →, ↓ then ↘ => →).
        if previous == vertical {
            return horizontal
        }

        return vertical
    }

    private func diagonalComponents(of direction: GestureDirection) -> (vertical: GestureDirection, horizontal: GestureDirection)? {
        switch direction {
        case .upRight:
            return (.up, .right)
        case .upLeft:
            return (.up, .left)
        case .downRight:
            return (.down, .right)
        case .downLeft:
            return (.down, .left)
        default:
            return nil
        }
    }
}
