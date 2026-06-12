import Foundation
import CoreGraphics

/// Content type for each key in the keyboard grid
enum KeyContent: Equatable {
    case consonant(Choseong)
    case symbol(String)
    case backspace
    case shift  // English mode: toggles next letter's case (one-shot shift)
}

/// Keyboard input mode (layout + input behavior)
enum KeyboardMode {
    case korean
    case symbol
    case english
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

    // Calculate key height based on available space.
    // Uses the fixed gridRows (4) so the Korean grid always occupies the same area,
    // even when English mode only renders 3 rows (English rows just grow a bit taller).
    static func keyHeight(for totalHeight: CGFloat, rowCount: Int = gridRows) -> CGFloat {
        let rows = max(rowCount, 1)
        let availableHeight = totalHeight - functionRowHeight - suggestionBarHeight - keySpacing * CGFloat(rows + 2)
        return availableHeight / CGFloat(rows)
    }

    // Number of rows in the active layout.
    static func rowCount(for mode: KeyboardMode) -> Int {
        return layout(for: mode).count
    }

    // Get key width for specific column and row
    static func keyWidth(for column: Int, row: Int, centerKeyWidth: CGFloat, mode: KeyboardMode = .korean) -> CGFloat {
        // English QWERTY: 10-column grid (centerKeyWidth = englishKeyWidth).
        // Row 0: 10 letters @ 1 unit; row 1: 9 letters @ 1 unit (centered by HStack);
        // row 2: shift @ 1.5 units + 7 letters @ 1 unit + backspace @ 1.5 units.
        if mode == .english {
            if row == 2 && (column == 0 || column == 8) {
                return centerKeyWidth * 1.5 + keySpacing * 0.5
            }
            return centerKeyWidth
        }

        let sideWidth = centerKeyWidth * symbolWidthRatio

        // Row 3: backspace (col 5) fills remaining space to match row 0-2 width
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

    // Layout for the active mode.
    static func layout(for mode: KeyboardMode) -> [[KeyContent]] {
        switch mode {
        case .korean: return koreanLayout
        case .symbol: return symbolLayout
        case .english: return englishLayout
        }
    }

    // Get number of columns for a row in the active layout.
    static func columnCount(for row: Int, mode: KeyboardMode) -> Int {
        let activeLayout = layout(for: mode)
        guard row >= 0 && row < activeLayout.count else { return 0 }
        return activeLayout[row].count
    }

    // English QWERTY: unit width based on 10 columns (row 0 sets the densest pitch).
    // Row 0 fills full width; rows 1 & 2 are slightly narrower (HStack centers them).
    static func englishKeyWidth(for totalWidth: CGFloat) -> CGFloat {
        let spacing = keySpacing * 11  // 11 gaps for 10 columns + edges
        return (totalWidth - spacing) / 10
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

    // English mode layout: standard 3-row QWERTY.
    // Row 0: 10 letters; row 1: 9 letters (centered); row 2: shift + 7 letters + backspace.
    // Tap = lowercase, drag up = uppercase (handled in the view model).
    // Shift key toggles one-shot uppercase via viewModel.isShiftEnabled.
    static let englishLayout: [[KeyContent]] = [
        [.symbol("q"), .symbol("w"), .symbol("e"), .symbol("r"), .symbol("t"), .symbol("y"), .symbol("u"), .symbol("i"), .symbol("o"), .symbol("p")],
        [.symbol("a"), .symbol("s"), .symbol("d"), .symbol("f"), .symbol("g"), .symbol("h"), .symbol("j"), .symbol("k"), .symbol("l")],
        [.shift, .symbol("z"), .symbol("x"), .symbol("c"), .symbol("v"), .symbol("b"), .symbol("n"), .symbol("m"), .backspace],
    ]

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
    static func keyContent(at row: Int, column: Int, mode: KeyboardMode) -> KeyContent? {
        let activeLayout = layout(for: mode)
        guard row >= 0 && row < activeLayout.count,
              column >= 0 && column < activeLayout[row].count else {
            return nil
        }
        return activeLayout[row][column]
    }

    // Get consonant at grid position (for Korean mode only)
    static func consonant(at row: Int, column: Int) -> Choseong? {
        guard let content = keyContent(at: row, column: column, mode: .korean) else {
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
