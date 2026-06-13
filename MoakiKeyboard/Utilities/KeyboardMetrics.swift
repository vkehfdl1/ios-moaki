import Foundation
import CoreGraphics

/// Content type for each key in the keyboard grid
enum KeyContent: Equatable {
    case consonant(Choseong)
    case vowel(Jungseong)
    case symbol(String)
    case backspace
    /// Slot rendered as empty (used in vowel-popup mode to hide the originating
    /// consonant key beneath the user's finger).
    case hidden
}

enum KeyboardMetrics {
    // Grid layout
    static let gridColumns = 7  // Expanded from 5 to 7
    static let gridRows = 4

    // Key sizing
    static let keySpacing: CGFloat = 4
    static let keyCornerRadius: CGFloat = 8

    // Width ratio for side symbol keys (relative to center keys)
    static let symbolWidthRatio: CGFloat = 0.35

    // Width ratio for action keys (backspace/return) relative to total width
    static let actionKeyWidthRatio: CGFloat = 0.20

    // Function row
    static let functionRowHeight: CGFloat = 44

    // Suggestion bar (단어 예측 후보 바)
    static let suggestionBarHeight: CGFloat = 40

    // Gesture thresholds
    static let gestureThreshold: CGFloat = 20        // Minimum distance to register direction
    static let reversalThreshold: CGFloat = 10       // Lower threshold for opposite direction reversals
    static let directionChangeThreshold: CGFloat = 15 // Distance before direction can change
    static let gestureTimeout: TimeInterval = 0.5    // Max time between direction changes

    /// Grid recognizer: minor/major axis ratio required to treat a stroke as a
    /// diagonal (↗ ↘ ↖ ↙). Higher = cardinals (ㅏㅓㅗㅜ) get more forgiving and
    /// diagonals (ㅣ/ㅡ) require a cleaner ~45° drag. ~0.6 ≈ 31° from the axis.
    static let diagonalRatio: CGFloat = 0.6

    // Calculate action key width (backspace/return) based on total width
    static func actionKeyWidth(for totalWidth: CGFloat) -> CGFloat {
        return totalWidth * actionKeyWidthRatio
    }

    // Calculate center key width based on available space
    // Row 0-2: side*2 + center*5 = 0.35*2 + 5 = 5.7 units
    static func centerKeyWidth(for totalWidth: CGFloat) -> CGFloat {
        let spacing = keySpacing * 8  // 8 gaps for 7 columns + edges
        let availableWidth = totalWidth - spacing
        return availableWidth / (symbolWidthRatio * 2 + 5)
    }

    // Calculate key height based on available space
    static func keyHeight(for totalHeight: CGFloat) -> CGFloat {
        let availableHeight = totalHeight - functionRowHeight - suggestionBarHeight - keySpacing * CGFloat(gridRows + 2)
        return availableHeight / CGFloat(gridRows)
    }

    // Get key width for specific column and row.
    // (`isVowelPopup` parameter retained for source compatibility; it no
    // longer affects sizing since the popup mode doesn't change layout.)
    static func keyWidth(for column: Int, row: Int, centerKeyWidth: CGFloat, isVowelPopup: Bool = false) -> CGFloat {
        let sideWidth = centerKeyWidth * symbolWidthRatio

        // Row 3 (consonant/symbol mode): backspace (col 5) fills remaining space to match row 0-2 width
        // Row 0-2 width: 2*sideWidth + 5*centerKeyWidth + 6*spacing
        // Row 3 without backspace: sideWidth + 4*centerKeyWidth + 5*spacing
        // backspaceWidth = sideWidth + centerKeyWidth + spacing
        if row == 3 && column == 5 {
            return sideWidth + centerKeyWidth + keySpacing
        }

        // Side columns (col 0 and col 6) are narrow
        if column == 0 || column == 6 {
            return sideWidth
        }

        return centerKeyWidth
    }

    // Get number of columns for a row in the active layout.
    // (`isVowelPopup`/`popupOrigin` params retained for source compatibility
    // but no longer affect layout - the new popup mode is a visual hint
    // overlay on top of the static koreanLayout.)
    static func columnCount(for row: Int, isSymbolMode: Bool, isVowelPopup: Bool = false, popupOrigin: (row: Int, column: Int)? = nil) -> Int {
        let layout: [[KeyContent]] = isSymbolMode ? symbolLayout : koreanLayout
        guard row >= 0 && row < layout.count else { return 0 }
        return layout[row].count
    }

    // Calculate key size based on available width (legacy method for compatibility)
    static func keySize(for totalWidth: CGFloat, totalHeight: CGFloat) -> CGSize {
        let keyWidth = centerKeyWidth(for: totalWidth)
        let keyHeightValue = keyHeight(for: totalHeight)
        return CGSize(width: keyWidth, height: keyHeightValue)
    }

    // Korean mode layout (7 columns for rows 0-2, 6 columns for row 3)
    // Left column: special symbols, Center: consonants, Right column: symbols
    // Row 3: backspace expands to fill remaining space
    static let koreanLayout: [[KeyContent]] = [
        [.symbol("~"), .consonant(.ㅃ), .consonant(.ㅉ), .consonant(.ㄸ), .consonant(.ㄲ), .consonant(.ㅆ), .symbol("!")],
        [.symbol("^"), .consonant(.ㅂ), .consonant(.ㅈ), .consonant(.ㄷ), .consonant(.ㄱ), .consonant(.ㅅ), .symbol("?")],
        [.symbol(";"), .consonant(.ㅁ), .consonant(.ㄴ), .consonant(.ㅇ), .consonant(.ㄹ), .consonant(.ㅎ), .symbol(".")],
        [.symbol("*"), .consonant(.ㅋ), .consonant(.ㅌ), .consonant(.ㅊ), .consonant(.ㅍ), .backspace],  // 6 columns
    ]

    // Symbol mode layout.
    // Same 7/7/7/6 geometry as Korean layout, values only are different.
    // Digits are centered:
    // row 0: 1 2 3
    // row 1: 4 5 6
    // row 2: 7 8 9
    // row 3: * 0 #
    static let symbolLayout: [[KeyContent]] = [
        [.symbol("~"), .symbol("!"), .symbol("1"), .symbol("2"), .symbol("3"), .symbol("@"), .symbol("$")],
        [.symbol("%"), .symbol("^"), .symbol("4"), .symbol("5"), .symbol("6"), .symbol("&"), .symbol("(")],
        [.symbol("="), .symbol("-"), .symbol("7"), .symbol("8"), .symbol("9"), .symbol("+"), .symbol(")")],
        [.symbol("/"), .symbol("?"), .symbol("*"), .symbol("0"), .symbol("#"), .backspace],
    ]

    // ─── Vowel popup mode (active when KeyboardSettings.useVowelPopupMode == true) ───
    //
    // STATIC design: every consonant slot has a fixed associated hidden
    // vowel, rendered as a small gray hint above the consonant glyph. Tap
    // a consonant -> C + (slot vowel). Drag to another slot -> C + (target
    // slot vowel). The grid never morphs; the vowel hints just brighten
    // during the SELECTING phase.
    //
    // Mapping: vowels-by-frequency rank N maps to consonant-slot rank N
    // (slots sorted by Euclidean distance from grid center (1.5, 3.0),
    // ties row asc then col asc). Slots ㅟ -> (0,0) and ㅞ -> (1,0) overflow
    // onto the ~/^ symbol cells (hybrid behavior; tap-in-place still
    // outputs the symbol, but drag-to-here selects the vowel).
    static let vowelsByFrequency: [Jungseong] = [
        .ㅏ, .ㅣ, .ㅓ, .ㅗ, .ㅡ, .ㅜ, .ㅔ, .ㅐ, .ㅑ, .ㅕ, .ㅛ,
        .ㅠ, .ㅢ, .ㅘ, .ㅝ, .ㅒ, .ㅖ, .ㅙ, .ㅚ, .ㅟ, .ㅞ
    ]

    /// Static slot -> vowel map. Keyed by row * 7 + column. 21 entries.
    /// Source: vowelsByFrequency rank N -> consonant-distance-rank N, plus
    /// ㅟ -> (0,0) and ㅞ -> (1,0) (the ~ and ^ symbol slots).
    static let vowelForSlotMap: [Int: Jungseong] = [
        // rank 0  ㅏ -> (1,3) ㄷ
        1 * 7 + 3: .ㅏ,
        // rank 1  ㅣ -> (2,3) ㅇ
        2 * 7 + 3: .ㅣ,
        // rank 2  ㅓ -> (1,2) ㅈ
        1 * 7 + 2: .ㅓ,
        // rank 3  ㅗ -> (1,4) ㄱ
        1 * 7 + 4: .ㅗ,
        // rank 4  ㅡ -> (2,2) ㄴ
        2 * 7 + 2: .ㅡ,
        // rank 5  ㅜ -> (2,4) ㄹ
        2 * 7 + 4: .ㅜ,
        // rank 6  ㅔ -> (0,3) ㄸ
        0 * 7 + 3: .ㅔ,
        // rank 7  ㅐ -> (3,3) ㅊ
        3 * 7 + 3: .ㅐ,
        // rank 8  ㅑ -> (0,2) ㅉ
        0 * 7 + 2: .ㅑ,
        // rank 9  ㅕ -> (0,4) ㄲ
        0 * 7 + 4: .ㅕ,
        // rank 10 ㅛ -> (3,2) ㅌ
        3 * 7 + 2: .ㅛ,
        // rank 11 ㅠ -> (3,4) ㅍ
        3 * 7 + 4: .ㅠ,
        // rank 12 ㅢ -> (1,1) ㅂ
        1 * 7 + 1: .ㅢ,
        // rank 13 ㅘ -> (1,5) ㅅ
        1 * 7 + 5: .ㅘ,
        // rank 14 ㅝ -> (2,1) ㅁ
        2 * 7 + 1: .ㅝ,
        // rank 15 ㅒ -> (2,5) ㅎ
        2 * 7 + 5: .ㅒ,
        // rank 16 ㅖ -> (0,1) ㅃ
        0 * 7 + 1: .ㅖ,
        // rank 17 ㅙ -> (0,5) ㅆ
        0 * 7 + 5: .ㅙ,
        // rank 18 ㅚ -> (3,1) ㅋ
        3 * 7 + 1: .ㅚ,
        // ㅟ -> (0,0) ~
        0 * 7 + 0: .ㅟ,
        // ㅞ -> (1,0) ^
        1 * 7 + 0: .ㅞ,
    ]

    /// Looks up the static vowel associated with a grid slot. Returns nil
    /// for slots without a vowel mapping (e.g. ⌫, ., ?, ;, *).
    static func vowelFor(row: Int, column: Int) -> Jungseong? {
        return vowelForSlotMap[row * 7 + column]
    }

    // Long press number mapping for Korean mode
    // Only basic consonants (row 1-2) have number mappings
    // ㅂㅈㄷㄱㅅ → 1 2 3 4 5
    // ㅁㄴㅇㄹㅎ → 6 7 8 9 0
    static let longPressNumbers: [[String?]] = [
        [nil, nil, nil, nil, nil, nil, nil],  // row 0 (쌍자음 - no numbers)
        [nil, "1", "2", "3", "4", "5", nil],  // row 1 (ㅂㅈㄷㄱㅅ)
        [nil, "6", "7", "8", "9", "0", nil],  // row 2 (ㅁㄴㅇㄹㅎ)
        [nil, nil, nil, nil, nil, nil],       // row 3 (ㅋㅌㅊㅍ + backspace) - 6 columns
    ]

    // Get key content at grid position for given mode.
    // (`isVowelPopup`/`popupOrigin` params retained for source compatibility
    // but no longer affect layout - the new popup mode is a visual hint
    // overlay on top of the static koreanLayout.)
    static func keyContent(at row: Int, column: Int, isSymbolMode: Bool, isVowelPopup: Bool = false, popupOrigin: (row: Int, column: Int)? = nil) -> KeyContent? {
        let layout: [[KeyContent]] = isSymbolMode ? symbolLayout : koreanLayout
        guard row >= 0 && row < layout.count,
              column >= 0 && column < layout[row].count else {
            return nil
        }
        return layout[row][column]
    }

    // Get consonant at grid position (for Korean mode only)
    static func consonant(at row: Int, column: Int) -> Choseong? {
        guard let content = keyContent(at: row, column: column, isSymbolMode: false) else {
            return nil
        }
        if case .consonant(let choseong) = content {
            return choseong
        }
        return nil
    }

    // Get long press number for position
    static func longPressNumber(at row: Int, column: Int) -> String? {
        guard row >= 0 && row < longPressNumbers.count,
              column >= 0 && column < longPressNumbers[row].count else {
            return nil
        }
        return longPressNumbers[row][column]
    }
}
