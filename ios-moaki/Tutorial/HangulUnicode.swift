import Foundation

enum HangulUnicode {
    private static let syllableBase: UInt32 = 0xAC00
    private static let syllableEnd: UInt32 = 0xD7A3
    private static let jongseongCount: UInt32 = 28
    private static let choseongOffset: UInt32 = 21 * 28 // 588

    struct Decomposed {
        let choseong: Int
        let jungseong: Int
        let jongseong: Int
    }

    static func decompose(_ char: Character) -> Decomposed? {
        guard let scalar = char.unicodeScalars.first else { return nil }
        let value = scalar.value
        guard value >= syllableBase && value <= syllableEnd else { return nil }

        let offset = value - syllableBase
        return Decomposed(
            choseong: Int(offset / choseongOffset),
            jungseong: Int((offset % choseongOffset) / jongseongCount),
            jongseong: Int(offset % jongseongCount)
        )
    }

    static func isHangulSyllable(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        return scalar.value >= syllableBase && scalar.value <= syllableEnd
    }

    /// Check if `input` character is a partial match for `target` character.
    /// e.g. "ㄱ" is partial of "가", "가" is partial of "간"
    static func isPartialMatch(input: Character, target: Character) -> Bool {
        // If they're equal, it's a full match, not partial
        if input == target { return false }

        guard let targetD = decompose(target) else { return false }

        // Case 1: input is a bare consonant (jamo), target is a syllable
        // Check if input matches the choseong of target
        if let scalar = input.unicodeScalars.first {
            let value = scalar.value
            // Hangul Compatibility Jamo consonants: ㄱ(0x3131) ~ ㅎ(0x314E)
            if value >= 0x3131 && value <= 0x314E {
                let choseongMap: [UInt32: Int] = [
                    0x3131: 0,  // ㄱ
                    0x3132: 1,  // ㄲ
                    0x3134: 2,  // ㄴ
                    0x3137: 3,  // ㄷ
                    0x3138: 4,  // ㄸ
                    0x3139: 5,  // ㄹ
                    0x3141: 6,  // ㅁ
                    0x3142: 7,  // ㅂ
                    0x3143: 8,  // ㅃ
                    0x3145: 9,  // ㅅ
                    0x3146: 10, // ㅆ
                    0x3147: 11, // ㅇ
                    0x3148: 12, // ㅈ
                    0x3149: 13, // ㅉ
                    0x314A: 14, // ㅊ
                    0x314B: 15, // ㅋ
                    0x314C: 16, // ㅌ
                    0x314D: 17, // ㅍ
                    0x314E: 18  // ㅎ
                ]
                if let choIndex = choseongMap[value], choIndex == targetD.choseong {
                    return true
                }
            }
        }

        // Case 2: input is a syllable without jongseong, target has jongseong
        if let inputD = decompose(input) {
            if inputD.choseong == targetD.choseong
                && inputD.jungseong == targetD.jungseong
                && inputD.jongseong == 0
                && targetD.jongseong != 0 {
                return true
            }
        }

        return false
    }
}
