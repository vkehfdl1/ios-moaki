import Foundation

enum HangulConstants {
    // Unicode Hangul Syllables block
    static let syllableBase: UInt32 = 0xAC00    // '가'
    static let syllableEnd: UInt32 = 0xD7A3     // '힣'

    // Counts
    static let choseongCount: UInt32 = 19
    static let jungseongCount: UInt32 = 21
    static let jongseongCount: UInt32 = 28

    // Offsets for syllable calculation
    static let jungseongOffset: UInt32 = jongseongCount           // 28
    static let choseongOffset: UInt32 = jungseongCount * jongseongCount  // 588

    // Compose a complete Hangul syllable
    static func composeSyllable(choseong: Choseong, jungseong: Jungseong, jongseong: Jongseong = .none) -> Character {
        let code = syllableBase
            + UInt32(choseong.rawValue) * choseongOffset
            + UInt32(jungseong.rawValue) * jungseongOffset
            + UInt32(jongseong.rawValue)
        return Character(UnicodeScalar(code)!)
    }

    // Decompose a Hangul syllable into its components
    static func decomposeSyllable(_ char: Character) -> (Choseong, Jungseong, Jongseong)? {
        guard let scalar = char.unicodeScalars.first else { return nil }
        let value = scalar.value

        guard value >= syllableBase && value <= syllableEnd else { return nil }

        let offset = value - syllableBase
        let choseongIndex = Int(offset / choseongOffset)
        let jungseongIndex = Int((offset % choseongOffset) / jungseongOffset)
        let jongseongIndex = Int(offset % jungseongOffset)

        guard let choseong = Choseong(rawValue: choseongIndex),
              let jungseong = Jungseong(rawValue: jungseongIndex),
              let jongseong = Jongseong(rawValue: jongseongIndex) else {
            return nil
        }

        return (choseong, jungseong, jongseong)
    }

    // Check if character is a Hangul syllable
    static func isHangulSyllable(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        return scalar.value >= syllableBase && scalar.value <= syllableEnd
    }

    // Check if character is a Hangul Jamo (compatibility)
    static func isHangulJamo(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        let value = scalar.value
        // Hangul Compatibility Jamo: U+3130 - U+318F
        return value >= 0x3130 && value <= 0x318F
    }
}
