import Foundation

class VowelResolver {
    private let patternTrie = VowelPattern.patternTrie

    private let maxCandidateCount = 64
    private let complexPreferenceBonus = 0.30
    private let threeStrokeBonus = 0.15
    private let partialMatchPenalty = 0.35
    private let missingChangePenalty = 0.40
    private let noRightEvidencePenalty = 0.60
    private let peekConfidenceThreshold = 0.90
    private let ambiguousPeekThreshold = 0.15

    struct Resolution {
        let vowel: Jungseong?
        let hasMoreMatches: Bool
    }

    private struct CandidateEvaluation {
        let directions: [GestureDirection]
        let match: PatternTrie.MatchResult
        let score: Double
    }

    func resolve(directions: [GestureDirection]) -> Resolution {
        guard !directions.isEmpty else {
            return Resolution(vowel: nil, hasMoreMatches: false)
        }

        let evaluations = evaluateCandidates(for: directions)
        guard let best = evaluations.max(by: { $0.score < $1.score }) else {
            return Resolution(vowel: nil, hasMoreMatches: false)
        }

        return Resolution(
            vowel: best.match.vowel,
            hasMoreMatches: best.match.hasLongerMatch
        )
    }

    // For real-time feedback during gesture
    func peekVowel(directions: [GestureDirection]) -> Jungseong? {
        guard !directions.isEmpty else { return nil }

        let evaluations = evaluateCandidates(for: directions)
        guard !evaluations.isEmpty else { return nil }

        let sorted = evaluations.sorted { $0.score > $1.score }
        guard let top = sorted.first, let topVowel = top.match.vowel else {
            return nil
        }

        let topIsExact = top.match.consumedCount == directions.count
        if topIsExact && top.score >= peekConfidenceThreshold {
            return topVowel
        }

        if top.match.hasLongerMatch {
            return nil
        }

        if sorted.count > 1 {
            let runnerUp = sorted[1]
            if abs(top.score - runnerUp.score) <= ambiguousPeekThreshold {
                return nil
            }
        }

        return topVowel
    }

    // Check if current directions could potentially match a vowel
    func hasPotentialMatch(directions: [GestureDirection]) -> Bool {
        guard !directions.isEmpty else { return false }
        let evaluations = evaluateCandidates(for: directions)
        return evaluations.contains { $0.match.vowel != nil || $0.match.hasLongerMatch }
    }

    private func evaluateCandidates(for directions: [GestureDirection]) -> [CandidateEvaluation] {
        let candidates = generateCandidates(from: directions)
        var evaluations: [CandidateEvaluation] = []

        for candidate in candidates {
            let match = patternTrie.match(candidate)
            let score = scoreCandidate(
                original: directions,
                candidate: candidate,
                match: match
            )
            evaluations.append(
                CandidateEvaluation(
                    directions: candidate,
                    match: match,
                    score: score
                )
            )
        }

        return evaluations
    }

    private func generateCandidates(from directions: [GestureDirection]) -> [[GestureDirection]] {
        var candidates: [[GestureDirection]] = []
        var queue: [[GestureDirection]] = [[]]

        for (index, direction) in directions.enumerated() {
            let options = normalizedOptions(for: direction, at: index)
            var nextQueue: [[GestureDirection]] = []

            for prefix in queue {
                for option in options {
                    var next = prefix
                    next.append(option)
                    nextQueue.append(next)
                    if nextQueue.count >= maxCandidateCount {
                        break
                    }
                }
                if nextQueue.count >= maxCandidateCount {
                    break
                }
            }

            queue = nextQueue
            if queue.isEmpty {
                break
            }
        }

        candidates.append(contentsOf: queue)
        if !candidates.contains(directions) {
            candidates.append(directions)
        }
        return candidates
    }

    private func normalizedOptions(for direction: GestureDirection, at index: Int) -> [GestureDirection] {
        var options: [GestureDirection] = [direction]

        if index == 0 {
            switch direction {
            case .upLeft:
                options.append(.up)
            case .downLeft:
                options.append(.down)
            default:
                break
            }
        }

        switch direction {
        case .upRight:
            options.append(contentsOf: [.up, .right])
        case .downRight:
            options.append(contentsOf: [.down, .right])
        case .upLeft:
            options.append(contentsOf: [.up, .left])
        case .downLeft:
            options.append(contentsOf: [.down, .left])
        default:
            break
        }

        var deduped: [GestureDirection] = []
        for option in options where !deduped.contains(option) {
            deduped.append(option)
        }
        return deduped
    }

    private func scoreCandidate(original: [GestureDirection],
                                candidate: [GestureDirection],
                                match: PatternTrie.MatchResult) -> Double {
        guard let vowel = match.vowel else {
            // Prefix-only matches are still useful for hasMoreMatches tracking.
            return match.hasLongerMatch ? 0.10 : 0.0
        }

        let consumedRatio = Double(match.consumedCount) / Double(max(candidate.count, 1))
        var score = consumedRatio

        if match.consumedCount < candidate.count {
            score -= partialMatchPenalty
        }

        if isComplexVowel(vowel) && match.consumedCount == candidate.count {
            score += complexPreferenceBonus
        }

        if isThreeStrokeSensitiveVowel(vowel) && match.consumedCount == 3 {
            score += threeStrokeBonus
        }

        if isThreeStrokeSensitiveVowel(vowel), !hasTwoDirectionChanges(in: original) {
            score -= missingChangePenalty
        }

        if vowel == .ㅞ && !hasRightFamilySecondStroke(in: original) {
            score -= noRightEvidencePenalty
        }

        return score
    }

    private func isThreeStrokeSensitiveVowel(_ vowel: Jungseong) -> Bool {
        switch vowel {
        case .ㅙ, .ㅞ, .ㅛ, .ㅠ, .ㅑ, .ㅕ:
            return true
        default:
            return false
        }
    }

    private func isComplexVowel(_ vowel: Jungseong) -> Bool {
        switch vowel {
        case .ㅙ, .ㅞ:
            return true
        default:
            return false
        }
    }

    private func hasTwoDirectionChanges(in directions: [GestureDirection]) -> Bool {
        guard directions.count >= 3 else { return false }

        var changes = 0
        var last = directions[0]
        for direction in directions.dropFirst() {
            if direction != last {
                changes += 1
                last = direction
            }
            if changes >= 2 {
                return true
            }
        }
        return false
    }

    private func hasRightFamilySecondStroke(in directions: [GestureDirection]) -> Bool {
        guard directions.count >= 2 else { return false }
        switch directions[1] {
        case .right, .upRight, .downRight:
            return true
        default:
            return false
        }
    }
}
