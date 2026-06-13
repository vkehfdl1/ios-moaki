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
    // HYBRID design (Option 2 + 보강): two vowel display channels.
    //
    // Channel A — 6 directional vowels (ㅏ ㅓ ㅗ ㅜ ㅣ ㅡ): overlay on the
    // 6 grid cells immediately adjacent to the touched consonant during the
    // SELECTING phase. Mapping derives from VowelPattern.swift (single-stroke
    // gestures) for muscle-memory parity with gesture mode:
    //     →  .right     → ㅏ
    //     ←  .left      → ㅓ
    //     ↑  .up        → ㅗ
    //     ↓  .down      → ㅜ
    //     ↗  .upRight   → ㅣ
    //     ↙  .downLeft  → ㅡ
    //
    // Channel B — 15 fixed vowels (the rest): tiny gray hint always visible
    // on 15 consonant slots, ranked by Euclidean distance from grid center
    // (1.5, 3.0). The 4 furthest consonant slots (ㅎ ㅃ ㅆ ㅋ) get no hint;
    // side symbols and backspace get no hint either.
    //
    // On finger release:
    //  - released on source slot (no movement) → inputConsonant only
    //    (composer routes; preserves b4d258e CV→batchim behavior)
    //  - released on a directional adjacent cell → C + directional vowel
    //  - released on a fixed-hint cell           → C + fixed vowel
    //  - released elsewhere                      → cancel

    /// Direction → vowel mapping for the 6 directional adjacent cells.
    /// Derived from VowelPattern.swift single-stroke entries.
    static let directionalVowelMap: [GestureDirection: Jungseong] = [
        .right:     .ㅏ,
        .left:      .ㅓ,
        .up:        .ㅗ,
        .down:      .ㅜ,
        .upRight:   .ㅣ,
        .downLeft:  .ㅡ,
    ]

    /// Grid offset (Δrow, Δcol) → basic vowel mapping for popup-mode
    /// cell-based hit-testing. The popup path uses this directly — it does
    /// NOT interpret stroke angle. The 6 entries mirror directionalVowelMap
    /// in spatial layout:
    ///   (0, +1)  right     → ㅏ
    ///   (0, -1)  left      → ㅓ
    ///   (-1, 0)  up        → ㅗ
    ///   (+1, 0)  down      → ㅜ
    ///   (-1, +1) upRight   → ㅣ
    ///   (+1, -1) downLeft  → ㅡ
    struct Offset: Hashable {
        let dRow: Int
        let dCol: Int
        init(_ dRow: Int, _ dCol: Int) {
            self.dRow = dRow
            self.dCol = dCol
        }
    }

    static let directionalVowelByOffset: [Offset: Jungseong] = [
        Offset(0,  1):  .ㅏ,   // right
        Offset(0, -1):  .ㅓ,   // left
        Offset(-1, 0):  .ㅗ,   // up
        Offset(1,  0):  .ㅜ,   // down
        Offset(-1, 1):  .ㅣ,   // upRight
        Offset(1, -1):  .ㅡ,   // downLeft
    ]

    /// Pure cell-position vowel lookup for popup mode. NO angle math.
    /// Computes offset from source → cell, checks the 6-entry directional
    /// map first, then the 15-entry fixed-hint map. Returns nil when the
    /// cell has no vowel mapping (e.g. far-tail consonants, symbols, backspace).
    static func popupVowelAt(cell: (row: Int, column: Int), source: (row: Int, column: Int)) -> Jungseong? {
        let dRow = cell.row - source.row
        let dCol = cell.column - source.column
        if let v = directionalVowelByOffset[Offset(dRow, dCol)] {
            return v
        }
        if let v = fixedVowelHintMap[cell.row * 7 + cell.column] {
            return v
        }
        return nil
    }

    /// Grid offset (Δrow, Δcol) for each gesture direction. Origin (0,0)
    /// is the touched consonant; positive row is down, positive col is right.
    static func gridOffset(for direction: GestureDirection) -> (dRow: Int, dCol: Int) {
        switch direction {
        case .right:     return (0, 1)
        case .left:      return (0, -1)
        case .up:        return (-1, 0)
        case .down:      return (1, 0)
        case .upRight:   return (-1, 1)
        case .upLeft:    return (-1, -1)
        case .downRight: return (1, 1)
        case .downLeft:  return (1, -1)
        }
    }

    /// Returns the directional adjacent cells (after edge/reserved clipping)
    /// for a consonant at (row, column). A cell is "reserved" (clipped) if
    /// it is off-grid, or contains a side symbol (~ ^ ; * ! ? .) or
    /// backspace. Cells occupied by OTHER consonants are still valid — the
    /// overlay paints the directional vowel on top of that consonant cell.
    static func directionalVowels(around row: Int, column: Int) -> [(row: Int, column: Int, vowel: Jungseong, direction: GestureDirection)] {
        var result: [(row: Int, column: Int, vowel: Jungseong, direction: GestureDirection)] = []
        for (dir, vowel) in directionalVowelMap {
            let off = gridOffset(for: dir)
            let r = row + off.dRow
            let c = column + off.dCol
            // Clip off-grid.
            guard r >= 0, r < gridRows else { continue }
            let cols = columnCount(for: r, isSymbolMode: false)
            guard c >= 0, c < cols else { continue }
            // Clip reserved (symbol/backspace) cells; only consonant cells
            // can host a directional vowel overlay.
            guard let content = keyContent(at: r, column: c, isSymbolMode: false) else { continue }
            switch content {
            case .consonant:
                result.append((r, c, vowel, dir))
            case .symbol, .backspace, .vowel, .hidden:
                continue
            }
        }
        return result
    }

    /// 15 fixed-vowel hints (frequency-ranked, dropping the 6 basic vowels
    /// covered by Channel A). Placed at the 15 consonant slots closest to
    /// the grid center.
    static let fixedVowelsByFrequency: [Jungseong] = [
        .ㅔ, .ㅐ, .ㅑ, .ㅕ, .ㅛ, .ㅠ, .ㅢ, .ㅘ, .ㅝ,
        .ㅒ, .ㅖ, .ㅙ, .ㅚ, .ㅟ, .ㅞ
    ]

    /// Static slot → fixed vowel hint map. Keyed by row * 7 + column.
    /// 15 entries — the remaining 4 consonant slots (ㅎ ㅃ ㅆ ㅋ) and all
    /// symbols/backspace have no fixed hint.
    static let fixedVowelHintMap: [Int: Jungseong] = [
        // Rank 0  ㅔ → (1,3) ㄷ
        1 * 7 + 3: .ㅔ,
        // Rank 1  ㅐ → (2,3) ㅇ
        2 * 7 + 3: .ㅐ,
        // Rank 2  ㅑ → (1,2) ㅈ
        1 * 7 + 2: .ㅑ,
        // Rank 3  ㅕ → (1,4) ㄱ
        1 * 7 + 4: .ㅕ,
        // Rank 4  ㅛ → (2,2) ㄴ
        2 * 7 + 2: .ㅛ,
        // Rank 5  ㅠ → (2,4) ㄹ
        2 * 7 + 4: .ㅠ,
        // Rank 6  ㅢ → (0,3) ㄸ
        0 * 7 + 3: .ㅢ,
        // Rank 7  ㅘ → (3,3) ㅊ
        3 * 7 + 3: .ㅘ,
        // Rank 8  ㅝ → (0,2) ㅉ
        0 * 7 + 2: .ㅝ,
        // Rank 9  ㅒ → (0,4) ㄲ
        0 * 7 + 4: .ㅒ,
        // Rank 10 ㅖ → (3,2) ㅌ
        3 * 7 + 2: .ㅖ,
        // Rank 11 ㅙ → (3,4) ㅍ
        3 * 7 + 4: .ㅙ,
        // Rank 12 ㅚ → (1,1) ㅂ
        1 * 7 + 1: .ㅚ,
        // Rank 13 ㅟ → (1,5) ㅅ
        1 * 7 + 5: .ㅟ,
        // Rank 14 ㅞ → (2,1) ㅁ
        2 * 7 + 1: .ㅞ,
    ]

    /// Looks up the fixed vowel hint associated with a grid slot. Returns
    /// nil for slots without a fixed-hint mapping (the 4 far-corner
    /// consonants and all symbol/backspace cells).
    static func fixedVowelHint(row: Int, column: Int) -> Jungseong? {
        return fixedVowelHintMap[row * 7 + column]
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
