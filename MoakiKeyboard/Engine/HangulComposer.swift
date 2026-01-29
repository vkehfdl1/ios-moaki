import Foundation

class HangulComposer {
    enum State: Equatable {
        case empty
        case choseong(Choseong)
        case choseongJungseong(Choseong, Jungseong)
        case complete(Choseong, Jungseong, Jongseong)
    }

    private(set) var state: State = .empty
    private(set) var composedText: String = ""

    var currentComposingCharacter: Character? {
        switch state {
        case .empty:
            return nil
        case .choseong(let cho):
            return cho.compatibilityCharacter
        case .choseongJungseong(let cho, let jung):
            return HangulConstants.composeSyllable(choseong: cho, jungseong: jung)
        case .complete(let cho, let jung, let jong):
            return HangulConstants.composeSyllable(choseong: cho, jungseong: jung, jongseong: jong)
        }
    }

    var displayText: String {
        if let composing = currentComposingCharacter {
            return composedText + String(composing)
        }
        return composedText
    }

    func reset() {
        state = .empty
        composedText = ""
    }

    /// Retrieves and clears any committed text waiting to be inserted
    func flushCommittedText() -> String {
        let text = composedText
        composedText = ""
        return text
    }

    func commitCurrent() {
        if let char = currentComposingCharacter {
            composedText.append(char)
        }
        state = .empty
    }

    // Input a consonant (choseong)
    func inputChoseong(_ choseong: Choseong) -> ComposerAction {
        switch state {
        case .empty:
            state = .choseong(choseong)
            return .update

        case .choseong:
            // Commit current choseong and start new one
            commitCurrent()
            state = .choseong(choseong)
            return .commitAndUpdate

        case .choseongJungseong(let cho, let jung):
            // Try to add as jongseong
            if let jongseong = Jongseong.from(choseong) {
                state = .complete(cho, jung, jongseong)
                return .update
            } else {
                // This consonant can't be jongseong (ㄸ, ㅃ, ㅉ)
                // Commit current and start new
                commitCurrent()
                state = .choseong(choseong)
                return .commitAndUpdate
            }

        case .complete(let cho, let jung, let jong):
            // Try to combine with existing jongseong
            if let doubleJong = jong.combineWith(choseong) {
                state = .complete(cho, jung, doubleJong)
                return .update
            } else {
                // Can't combine - commit and start new
                commitCurrent()
                state = .choseong(choseong)
                return .commitAndUpdate
            }
        }
    }

    // Input a vowel (jungseong)
    func inputJungseong(_ jungseong: Jungseong) -> ComposerAction {
        switch state {
        case .empty:
            // Vowel without consonant - use ㅇ as placeholder? Or just output the vowel
            // For now, output standalone vowel
            composedText.append(jungseong.compatibilityCharacter)
            return .commit

        case .choseong(let cho):
            state = .choseongJungseong(cho, jungseong)
            return .update

        case .choseongJungseong(let cho, let jung):
            // Try to combine vowels
            if let combined = combineVowels(jung, jungseong) {
                state = .choseongJungseong(cho, combined)
                return .update
            } else {
                // Can't combine - commit and output standalone vowel
                commitCurrent()
                composedText.append(jungseong.compatibilityCharacter)
                return .commitAndCommit
            }

        case .complete(let cho, let jung, let jong):
            // Vowel after complete syllable - move jongseong to new syllable
            if let split = jong.splitDoubleJongseong() {
                // Double jongseong - keep first part, move second
                let previousChar = HangulConstants.composeSyllable(choseong: cho, jungseong: jung, jongseong: split.0)
                composedText.append(previousChar)
                state = .choseongJungseong(split.1, jungseong)
                return .commitAndUpdate
            } else if let newChoseong = jong.toChoseong {
                // Single jongseong - move to new syllable
                let previousChar = HangulConstants.composeSyllable(choseong: cho, jungseong: jung)
                composedText.append(previousChar)
                state = .choseongJungseong(newChoseong, jungseong)
                return .commitAndUpdate
            } else {
                // Shouldn't happen, but handle gracefully
                commitCurrent()
                composedText.append(jungseong.compatibilityCharacter)
                return .commitAndCommit
            }
        }
    }

    // Delete the last input
    func deleteBackward() -> ComposerAction {
        switch state {
        case .empty:
            if !composedText.isEmpty {
                let lastChar = composedText.removeLast()
                // If it's a composed syllable, decompose and continue editing
                if let (cho, jung, jong) = HangulConstants.decomposeSyllable(lastChar) {
                    if jong == .none {
                        state = .choseong(cho)
                    } else {
                        state = .complete(cho, jung, jong)
                    }
                    return .update
                }
                return .delete
            }
            return .none

        case .choseong:
            state = .empty
            return .update

        case .choseongJungseong(let cho, _):
            state = .choseong(cho)
            return .update

        case .complete(let cho, let jung, let jong):
            // Check if jongseong is double
            if let split = jong.splitDoubleJongseong() {
                state = .complete(cho, jung, split.0)
            } else {
                state = .choseongJungseong(cho, jung)
            }
            return .update
        }
    }

    // Try to combine two vowels
    private func combineVowels(_ first: Jungseong, _ second: Jungseong) -> Jungseong? {
        switch (first, second) {
        case (.ㅗ, .ㅏ): return .ㅘ
        case (.ㅗ, .ㅐ): return .ㅙ
        case (.ㅗ, .ㅣ): return .ㅚ
        case (.ㅜ, .ㅓ): return .ㅝ
        case (.ㅜ, .ㅔ): return .ㅞ
        case (.ㅜ, .ㅣ): return .ㅟ
        case (.ㅡ, .ㅣ): return .ㅢ
        default: return nil
        }
    }

    enum ComposerAction {
        case none           // No change
        case update         // Update the composing character
        case commit         // Commit character to text
        case delete         // Delete from text
        case commitAndUpdate    // Commit previous and update composing
        case commitAndCommit    // Commit previous and commit new
    }
}
