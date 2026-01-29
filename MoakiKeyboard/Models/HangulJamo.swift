import Foundation

// MARK: - Choseong (초성) - 19 consonants
enum Choseong: Int, CaseIterable {
    case ㄱ = 0, ㄲ, ㄴ, ㄷ, ㄸ, ㄹ, ㅁ, ㅂ, ㅃ, ㅅ
    case ㅆ, ㅇ, ㅈ, ㅉ, ㅊ, ㅋ, ㅌ, ㅍ, ㅎ

    var character: Character {
        let baseCode: UInt32 = 0x1100
        return Character(UnicodeScalar(baseCode + UInt32(rawValue))!)
    }

    var compatibilityCharacter: Character {
        let chars: [Character] = ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ",
                                   "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
        return chars[rawValue]
    }
}

// MARK: - Jungseong (중성) - 21 vowels
enum Jungseong: Int, CaseIterable {
    case ㅏ = 0, ㅐ, ㅑ, ㅒ, ㅓ, ㅔ, ㅕ, ㅖ, ㅗ, ㅘ
    case ㅙ, ㅚ, ㅛ, ㅜ, ㅝ, ㅞ, ㅟ, ㅠ, ㅡ, ㅢ
    case ㅣ

    var character: Character {
        let baseCode: UInt32 = 0x1161
        return Character(UnicodeScalar(baseCode + UInt32(rawValue))!)
    }

    var compatibilityCharacter: Character {
        let chars: [Character] = ["ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ",
                                   "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ",
                                   "ㅣ"]
        return chars[rawValue]
    }
}

// MARK: - Jongseong (종성) - 28 (including none)
enum Jongseong: Int, CaseIterable {
    case none = 0
    case ㄱ, ㄲ, ㄳ, ㄴ, ㄵ, ㄶ, ㄷ, ㄹ, ㄺ
    case ㄻ, ㄼ, ㄽ, ㄾ, ㄿ, ㅀ, ㅁ, ㅂ, ㅄ, ㅅ
    case ㅆ, ㅇ, ㅈ, ㅊ, ㅋ, ㅌ, ㅍ, ㅎ

    var character: Character? {
        guard self != .none else { return nil }
        let baseCode: UInt32 = 0x11A7
        return Character(UnicodeScalar(baseCode + UInt32(rawValue))!)
    }

    var compatibilityCharacter: Character? {
        guard self != .none else { return nil }
        let chars: [Character] = ["ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ",
                                   "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ", "ㅄ", "ㅅ",
                                   "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
        return chars[rawValue - 1]
    }

    // Convert Jongseong to Choseong (for when vowel follows)
    var toChoseong: Choseong? {
        switch self {
        case .none: return nil
        case .ㄱ: return .ㄱ
        case .ㄲ: return .ㄲ
        case .ㄴ: return .ㄴ
        case .ㄷ: return .ㄷ
        case .ㄹ: return .ㄹ
        case .ㅁ: return .ㅁ
        case .ㅂ: return .ㅂ
        case .ㅅ: return .ㅅ
        case .ㅆ: return .ㅆ
        case .ㅇ: return .ㅇ
        case .ㅈ: return .ㅈ
        case .ㅊ: return .ㅊ
        case .ㅋ: return .ㅋ
        case .ㅌ: return .ㅌ
        case .ㅍ: return .ㅍ
        case .ㅎ: return .ㅎ
        // Double consonants - return the second part
        case .ㄳ, .ㄵ, .ㄶ, .ㄺ, .ㄻ, .ㄼ, .ㄽ, .ㄾ, .ㄿ, .ㅀ, .ㅄ:
            return splitDoubleJongseong()?.1
        }
    }

    // Split double Jongseong into (remaining Jongseong, new Choseong)
    func splitDoubleJongseong() -> (Jongseong, Choseong)? {
        switch self {
        case .ㄳ: return (.ㄱ, .ㅅ)
        case .ㄵ: return (.ㄴ, .ㅈ)
        case .ㄶ: return (.ㄴ, .ㅎ)
        case .ㄺ: return (.ㄹ, .ㄱ)
        case .ㄻ: return (.ㄹ, .ㅁ)
        case .ㄼ: return (.ㄹ, .ㅂ)
        case .ㄽ: return (.ㄹ, .ㅅ)
        case .ㄾ: return (.ㄹ, .ㅌ)
        case .ㄿ: return (.ㄹ, .ㅍ)
        case .ㅀ: return (.ㄹ, .ㅎ)
        case .ㅄ: return (.ㅂ, .ㅅ)
        default: return nil
        }
    }

    // Check if this Jongseong can combine with a Choseong to form double
    func combineWith(_ choseong: Choseong) -> Jongseong? {
        switch (self, choseong) {
        case (.ㄱ, .ㅅ): return .ㄳ
        case (.ㄴ, .ㅈ): return .ㄵ
        case (.ㄴ, .ㅎ): return .ㄶ
        case (.ㄹ, .ㄱ): return .ㄺ
        case (.ㄹ, .ㅁ): return .ㄻ
        case (.ㄹ, .ㅂ): return .ㄼ
        case (.ㄹ, .ㅅ): return .ㄽ
        case (.ㄹ, .ㅌ): return .ㄾ
        case (.ㄹ, .ㅍ): return .ㄿ
        case (.ㄹ, .ㅎ): return .ㅀ
        case (.ㅂ, .ㅅ): return .ㅄ
        default: return nil
        }
    }

    // Create Jongseong from Choseong
    static func from(_ choseong: Choseong) -> Jongseong? {
        switch choseong {
        case .ㄱ: return .ㄱ
        case .ㄲ: return .ㄲ
        case .ㄴ: return .ㄴ
        case .ㄷ: return .ㄷ
        case .ㄹ: return .ㄹ
        case .ㅁ: return .ㅁ
        case .ㅂ: return .ㅂ
        case .ㅅ: return .ㅅ
        case .ㅆ: return .ㅆ
        case .ㅇ: return .ㅇ
        case .ㅈ: return .ㅈ
        case .ㅊ: return .ㅊ
        case .ㅋ: return .ㅋ
        case .ㅌ: return .ㅌ
        case .ㅍ: return .ㅍ
        case .ㅎ: return .ㅎ
        // These consonants cannot be Jongseong
        case .ㄸ, .ㅃ, .ㅉ: return nil
        }
    }
}
