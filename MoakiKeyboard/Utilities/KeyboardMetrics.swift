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

    // Get key width for specific column and row
    static func keyWidth(for column: Int, row: Int, centerKeyWidth: CGFloat, isVowelPopup: Bool = false) -> CGFloat {
        let sideWidth = centerKeyWidth * symbolWidthRatio

        // Vowel popup row 3 is 7 columns: [* ㅡ ㅐ ㅔ ㅞ ㅟ ㅢ]
        // Layout matches rows 0-2 exactly (side, 5 center, side).
        if isVowelPopup && row == 3 {
            if column == 0 || column == 6 { return sideWidth }
            return centerKeyWidth
        }

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
    static func columnCount(for row: Int, isSymbolMode: Bool, isVowelPopup: Bool = false, popupOrigin: (row: Int, column: Int)? = nil) -> Int {
        let layout: [[KeyContent]]
        if isSymbolMode {
            layout = symbolLayout
        } else if isVowelPopup {
            layout = vowelPopupLayout(consonantAt: popupOrigin ?? (1, 3))
        } else {
            layout = koreanLayout
        }
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
    // Frequency-ordered vowels (most frequent first). When the user touches a
    // consonant, vowels are placed onto the 22 closest-to-center "candidate"
    // slots (sorted by Euclidean distance from grid center [1.5, 3.0]), with
    // ranks 0..20 for the 21 vowels and rank 21 reserved as a spillover slot.
    // The touched-consonant slot K is skipped: vowels with frequency-rank
    // fv < K stay at rank fv, vowels with fv >= K cascade to rank fv+1.
    // This guarantees a coherent layout regardless of which consonant is held.
    static let vowelsByFrequency: [Jungseong] = [
        .ㅏ, .ㅣ, .ㅓ, .ㅗ, .ㅡ, .ㅜ, .ㅔ, .ㅐ, .ㅑ, .ㅕ, .ㅛ,
        .ㅠ, .ㅢ, .ㅘ, .ㅝ, .ㅒ, .ㅖ, .ㅙ, .ㅚ, .ㅟ, .ㅞ
    ]

    /// 22 candidate slots, sorted by Euclidean distance from grid center
    /// (row 1.5, col 3.0), ties broken by row asc then col asc. Slots
    /// reserved as essentials (⌫ at (3,5), . at (2,6), ? at (1,6)) are
    /// excluded. The 21 vowels fill ranks 0..20; rank 21 is spillover.
    static let vowelPositionRanks: [(row: Int, column: Int)] = [
        (1, 3), (2, 3),                  // dist 0.5
        (1, 2), (1, 4), (2, 2), (2, 4),  // dist 1.118
        (0, 3), (3, 3),                  // dist 1.5
        (0, 2), (0, 4), (3, 2), (3, 4),  // dist 1.803
        (1, 1), (1, 5), (2, 1), (2, 5),  // dist 2.062
        (0, 1), (0, 5), (3, 1),          // dist 2.5
        (1, 0), (2, 0),                  // dist 3.041
        (0, 0)                           // dist 3.354 — spillover (rank 21)
    ]

    /// Builds the popup layout for a specific consonant slot. The touched
    /// slot is rendered as .hidden so the finger doesn't cover it; the 21
    /// vowels are placed by frequency, cascading around the touched slot.
    /// Reserved keys ⌫/./? are always present. Slots (0,6) and (3,0) are
    /// blank — the original ! and * symbols are sacrificed in popup mode.
    static func vowelPopupLayout(consonantAt slot: (row: Int, column: Int)) -> [[KeyContent]] {
        // 4 rows, with rows 0-2 having 7 cols and row 3 having 7 cols (popup
        // row 3 matches rows 0-2; koreanLayout row 3 is 6 cols).
        var grid: [[KeyContent]] = [
            Array(repeating: KeyContent.symbol(""), count: 7),
            Array(repeating: KeyContent.symbol(""), count: 7),
            Array(repeating: KeyContent.symbol(""), count: 7),
            Array(repeating: KeyContent.symbol(""), count: 7),
        ]

        // Reserved essentials
        grid[3][5] = .backspace
        grid[2][6] = .symbol(".")
        grid[1][6] = .symbol("?")

        // Find rank K of the touched consonant slot. Defensive: if not found
        // (shouldn't happen for the standard consonant grid), fall through
        // with no cascade.
        let K: Int? = {
            for (i, p) in vowelPositionRanks.enumerated() {
                if p.row == slot.row && p.column == slot.column { return i }
            }
            return nil
        }()

        // Place each vowel at its target position rank.
        for (fv, vowel) in vowelsByFrequency.enumerated() {
            let targetRank: Int
            if let k = K, fv >= k {
                targetRank = fv + 1
            } else {
                targetRank = fv
            }
            guard targetRank < vowelPositionRanks.count else { continue }
            let pos = vowelPositionRanks[targetRank]
            // Don't overwrite reserved slots (shouldn't collide, but safe).
            guard pos.row != 3 || pos.column != 5 else { continue }
            guard pos.row != 2 || pos.column != 6 else { continue }
            guard pos.row != 1 || pos.column != 6 else { continue }
            grid[pos.row][pos.column] = .vowel(vowel)
        }

        // Blank out (0,6), (3,0) — unused candidates whose original
        // koreanLayout symbols (! and *) are sacrificed in popup mode.
        // Also blank the touched consonant slot explicitly so it stays hidden
        // even though the view layer also forces it via popupOrigin.
        grid[0][6] = .symbol("")
        grid[3][0] = .symbol("")
        if slot.row >= 0, slot.row < grid.count,
           slot.column >= 0, slot.column < grid[slot.row].count {
            grid[slot.row][slot.column] = .hidden
        }

        return grid
    }

    /// Legacy non-parameterized layout. Returns the layout for an "average"
    /// touched slot (ㄷ at (1,3), the most central consonant). Used by code
    /// paths (e.g. metrics queries) that don't know the touched slot.
    static var vowelPopupLayout: [[KeyContent]] {
        return vowelPopupLayout(consonantAt: (1, 3))
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

    // Get key content at grid position for given mode
    static func keyContent(at row: Int, column: Int, isSymbolMode: Bool, isVowelPopup: Bool = false, popupOrigin: (row: Int, column: Int)? = nil) -> KeyContent? {
        let layout: [[KeyContent]]
        if isSymbolMode {
            layout = symbolLayout
        } else if isVowelPopup {
            layout = vowelPopupLayout(consonantAt: popupOrigin ?? (1, 3))
        } else {
            layout = koreanLayout
        }
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
