import Foundation

struct VowelPattern {
    let vowel: Jungseong
    let directions: [GestureDirection]

    init(_ vowel: Jungseong, _ directions: GestureDirection...) {
        self.vowel = vowel
        self.directions = directions
    }

    static let allPatterns: [VowelPattern] = [
        // Basic vowels (↖→↑만 정규화. 구분 대각선: ↗=ㅣ, ↙=ㅡ)
        VowelPattern(.ㅗ, .up),                           // ↑ (↖도 정규화로 처리됨)
        VowelPattern(.ㅜ, .down),                         // ↓
        VowelPattern(.ㅏ, .right),                        // →
        VowelPattern(.ㅓ, .left),                         // ←
        VowelPattern(.ㅡ, .downLeft),                     // ↙ → ㅡ
        VowelPattern(.ㅣ, .upRight),                      // ↗ → ㅣ

        // Y-vowels (triple direction)
        VowelPattern(.ㅛ, .up, .down, .up),               // ↑↓↑
        VowelPattern(.ㅠ, .down, .up, .down),             // ↓↑↓
        VowelPattern(.ㅑ, .right, .left, .right),         // →←→
        VowelPattern(.ㅕ, .left, .right, .left),          // ←→←

        // Complex vowels (diphthongs)
        VowelPattern(.ㅘ, .up, .right),                   // ↑→
        VowelPattern(.ㅙ, .up, .right, .left),            // ↑→←
        VowelPattern(.ㅝ, .down, .left),                  // ↓←
        VowelPattern(.ㅞ, .down, .left, .right),          // ↓←→
        VowelPattern(.ㅚ, .up, .down),                    // ↑↓
        VowelPattern(.ㅟ, .down, .up),                    // ↓↑

        // Ae/E vowels
        VowelPattern(.ㅐ, .right, .left),                 // →←
        VowelPattern(.ㅒ, .right, .left, .right, .left),  // →←→←
        VowelPattern(.ㅔ, .left, .right),                 // ←→
        VowelPattern(.ㅖ, .left, .right, .left, .right),  // ←→←→

        // Eu-i (ㅡ + ㅣ)
        VowelPattern(.ㅢ, .downRight, .upLeft),           // ↘↖ (오른쪽아래-왼쪽위)
        VowelPattern(.ㅢ, .downRight, .up),               // ↘↑ (오른쪽아래-위)
        VowelPattern(.ㅢ, .downLeft, .up),                // ↙↑ — ㅡ 긋고 ㅣ로 꺾기 (↗/↖도 정규화로 ↑가 됨)

        // 즉시 보정 (떼기 전 ㅏ↔ㅣ): 인접 단모음이 잘못 나왔을 때 이어서 정정
        VowelPattern(.ㅣ, .right, .up),                   // ㅏ(→) 뒤 ↑로 올리면 → ㅣ
        VowelPattern(.ㅏ, .upRight, .right),              // ㅣ(↗) 뒤 →로 그으면 → ㅏ
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

    /// Valid next stroke directions from the node reached by `directions`,
    /// each paired with the vowel completed by that stroke (nil if only a prefix).
    func continuations(_ directions: [GestureDirection]) -> [(direction: GestureDirection, vowel: Jungseong?)] {
        var current = root
        for direction in directions {
            guard let next = current.children[direction] else { return [] }
            current = next
        }
        return current.children.map { (direction: $0.key, vowel: $0.value.vowel) }
    }
}
