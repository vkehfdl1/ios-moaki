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

        let result = patternTrie.match(directions)
        return Resolution(
            vowel: result.vowel,
            hasMoreMatches: result.hasLongerMatch
        )
    }

    // For real-time feedback during gesture
    func peekVowel(directions: [GestureDirection]) -> Jungseong? {
        guard !directions.isEmpty else { return nil }
        let result = patternTrie.match(directions)
        return result.vowel
    }

    // Check if current directions could potentially match a vowel
    func hasPotentialMatch(directions: [GestureDirection]) -> Bool {
        guard !directions.isEmpty else { return false }
        let result = patternTrie.match(directions)
        return result.vowel != nil || result.hasLongerMatch
    }
}
