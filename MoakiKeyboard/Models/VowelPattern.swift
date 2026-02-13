import Foundation

struct VowelPattern {
    let vowel: Jungseong
    let directions: [GestureDirection]

    init(_ vowel: Jungseong, _ directions: GestureDirection...) {
        self.vowel = vowel
        self.directions = directions
    }

    static let allPatterns: [VowelPattern] = [
        // Basic vowels (왼쪽 대각선만 정규화: ↖→↑, ↙→↓)
        VowelPattern(.ㅗ, .up),                           // ↑ (↖도 정규화로 처리됨)
        VowelPattern(.ㅜ, .down),                         // ↓ (↙도 정규화로 처리됨)
        VowelPattern(.ㅏ, .right),                        // →
        VowelPattern(.ㅓ, .left),                         // ←
        VowelPattern(.ㅡ, .downRight),                    // ↘ → ㅡ
        VowelPattern(.ㅣ, .upRight),                      // ↗ → ㅣ

        // Y-vowels (triple direction)
        VowelPattern(.ㅛ, .up, .down, .up),               // ↑↓↑
        VowelPattern(.ㅛ, .up, .downRight, .up),          // ↖↘↖ (정규화 후)
        VowelPattern(.ㅛ, .up, .down, .upRight),          // ↑↓↗ (세 번째 획이 ↗로 빠질 때)
        VowelPattern(.ㅛ, .up, .downRight, .upRight),     // ↑↘↗ (중간+세 번째 모두 오른쪽 대각선)
        VowelPattern(.ㅠ, .down, .up, .down),             // ↓↑↓
        VowelPattern(.ㅠ, .down, .upRight, .down),        // ↙↗↙ (정규화 후)
        VowelPattern(.ㅠ, .down, .up, .downRight),        // ↓↑↘ (세 번째 획이 ↘로 빠질 때)
        VowelPattern(.ㅠ, .down, .upRight, .downRight),   // ↓↗↘ (중간+세 번째 모두 오른쪽 대각선)
        VowelPattern(.ㅑ, .right, .left, .right),         // →←→
        VowelPattern(.ㅕ, .left, .right, .left),          // ←→←

        // Complex vowels (diphthongs)
        VowelPattern(.ㅘ, .up, .right),                   // ↑→
        VowelPattern(.ㅙ, .up, .right, .left),            // ↑→←
        VowelPattern(.ㅙ, .up, .right, .down),            // ↑→↓ (세 번째 획이 ↙로 빠진 입력 정규화)
        VowelPattern(.ㅙ, .up, .upRight, .left),          // ↑↗← (두 번째 획 drift)
        VowelPattern(.ㅙ, .up, .upRight, .down),          // ↑↗↓ (두 번째+세 번째 획 drift)
        VowelPattern(.ㅝ, .down, .left),                  // ↓←
        VowelPattern(.ㅞ, .down, .right, .left),          // ↓→←
        VowelPattern(.ㅞ, .down, .right, .down),          // ↓→↓ (세 번째 획이 ↙로 빠진 입력 정규화)
        VowelPattern(.ㅞ, .down, .downRight, .left),      // ↓↘← (두 번째 획 drift)
        VowelPattern(.ㅞ, .down, .downRight, .down),      // ↓↘↓ (두 번째+세 번째 획 drift)
        VowelPattern(.ㅚ, .up, .down),                    // ↑↓
        VowelPattern(.ㅟ, .down, .up),                    // ↓↑

        // Ae/E vowels
        VowelPattern(.ㅐ, .right, .left),                 // →←
        VowelPattern(.ㅒ, .right, .left, .right, .left),  // →←→←
        VowelPattern(.ㅔ, .left, .right),                 // ←→
        VowelPattern(.ㅖ, .left, .right, .left, .right),  // ←→←→

        // Eu-i (ㅡ + ㅣ)
        VowelPattern(.ㅢ, .downRight, .upRight),          // ↘↗ (ㅡ + ㅣ 대각선)
        VowelPattern(.ㅢ, .downRight, .up),               // ↘↑ (ㅡ + 수직 위)
    ]

    // Build a trie for efficient pattern matching
    static let patternTrie: PatternTrie = {
        let trie = PatternTrie()
        for pattern in allPatterns {
            trie.insert(pattern)
        }
        return trie
    }()
}

// Trie for efficient pattern matching
class PatternTrie {
    class Node {
        var children: [GestureDirection: Node] = [:]
        var vowel: Jungseong?
        var isPartialMatch: Bool = false // True if this is a prefix of a longer pattern
    }

    let root = Node()

    func insert(_ pattern: VowelPattern) {
        var current = root
        for (index, direction) in pattern.directions.enumerated() {
            if current.children[direction] == nil {
                current.children[direction] = Node()
            }
            current = current.children[direction]!

            // Mark intermediate nodes as partial matches
            if index < pattern.directions.count - 1 {
                current.isPartialMatch = true
            }
        }
        current.vowel = pattern.vowel
    }

    struct MatchResult {
        let vowel: Jungseong?
        let consumedCount: Int
        let hasLongerMatch: Bool
    }

    func match(_ directions: [GestureDirection]) -> MatchResult {
        var current = root
        var lastMatch: (vowel: Jungseong, count: Int)?
        var hasLongerMatch = false

        for (index, direction) in directions.enumerated() {
            guard let next = current.children[direction] else {
                break
            }
            current = next

            if let vowel = current.vowel {
                lastMatch = (vowel, index + 1)
            }

            if index == directions.count - 1 && !current.children.isEmpty {
                hasLongerMatch = true
            }
        }

        if let match = lastMatch {
            return MatchResult(vowel: match.vowel, consumedCount: match.count, hasLongerMatch: hasLongerMatch)
        }

        return MatchResult(vowel: nil, consumedCount: 0, hasLongerMatch: !current.children.isEmpty)
    }
}
