# HotFix #15 Number Keypad Long-Press Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Prevent duplicate consonant insertion after long-press number input on Korean consonant keys.

**Architecture:** Keep gesture ownership in `KeyView`, but make long-press consumption explicit in `KeyboardViewModel`. A dedicated long-press entrypoint marks the current gesture as handled and `gestureEnded` skips normal consonant resolution for that one interaction.

**Tech Stack:** Swift, SwiftUI, XCTest, `xcodebuild`

---

### Task 1: Add Failing Regression Tests For Long-Press Number Flow

**Files:**
- Create: `MoakiKeyboardTests/KeyboardViewModelLongPressTests.swift`
- Test: `MoakiKeyboardTests/KeyboardViewModelLongPressTests.swift`

**Step 1: Write the failing test**

```swift
import XCTest
@testable import MoakiKeyboard

final class KeyboardViewModelLongPressTests: XCTestCase {
    private var viewModel: KeyboardViewModel!
    private var delegate: SpyKeyboardDelegate!

    override func setUp() {
        super.setUp()
        viewModel = KeyboardViewModel()
        delegate = SpyKeyboardDelegate()
        viewModel.delegate = delegate
    }

    override func tearDown() {
        viewModel = nil
        delegate = nil
        super.tearDown()
    }

    func testLongPressNumberThenGestureEnd_insertsOnlyNumber() {
        viewModel.gestureStarted(row: 1, column: 1, at: .zero) // ㅂ key
        viewModel.inputLongPressNumber("1")
        viewModel.gestureEnded(row: 1, column: 1)

        XCTAssertEqual(delegate.insertedTexts, ["1"])
        XCTAssertEqual(delegate.composingUpdates.count, 0)
    }

    func testNormalTapStillInputsConsonant() {
        viewModel.gestureStarted(row: 1, column: 1, at: .zero) // ㅂ key
        viewModel.gestureEnded(row: 1, column: 1)

        XCTAssertEqual(delegate.insertedTexts, [])
        XCTAssertEqual(delegate.composingUpdates.last?.current, "ㅂ")
    }

    func testLongPressSuppressionResetsForNextGesture() {
        viewModel.gestureStarted(row: 1, column: 1, at: .zero)
        viewModel.inputLongPressNumber("1")
        viewModel.gestureEnded(row: 1, column: 1)

        viewModel.gestureStarted(row: 1, column: 2, at: .zero) // ㅈ key
        viewModel.gestureEnded(row: 1, column: 2)

        XCTAssertEqual(delegate.insertedTexts, ["1"])
        XCTAssertEqual(delegate.composingUpdates.last?.current, "ㅈ")
    }
}

private final class SpyKeyboardDelegate: KeyboardViewModelDelegate {
    struct ComposingUpdate: Equatable {
        let previous: String
        let current: String
    }

    var insertedTexts: [String] = []
    var deleteCount = 0
    var composingUpdates: [ComposingUpdate] = []
    var switchKeyboardCount = 0
    var hapticCount = 0

    func insertText(_ text: String) { insertedTexts.append(text) }
    func deleteBackward() { deleteCount += 1 }
    func updateComposingText(from previous: String, to current: String) {
        composingUpdates.append(.init(previous: previous, current: current))
    }
    func switchToNextKeyboard() { switchKeyboardCount += 1 }
    func triggerHapticFeedback() { hapticCount += 1 }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme MoakiKeyboardTests -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:MoakiKeyboardTests/KeyboardViewModelLongPressTests`  
Expected: FAIL (missing `inputLongPressNumber(_:)` and/or duplicate consonant behavior).

**Step 3: Commit**

```bash
git add MoakiKeyboardTests/KeyboardViewModelLongPressTests.swift
git commit -m "test: add long-press number regression coverage"
```

### Task 2: Implement Long-Press Consumption In KeyboardViewModel

**Files:**
- Modify: `MoakiKeyboard/Views/KeyboardView.swift`
- Test: `MoakiKeyboardTests/KeyboardViewModelLongPressTests.swift`

**Step 1: Write minimal implementation**

```swift
final class KeyboardViewModel: ObservableObject {
    // ...
    private var didHandleLongPressNumber = false

    func inputLongPressNumber(_ number: String) {
        didHandleLongPressNumber = true
        inputNumber(number)
    }

    func gestureStarted(row: Int, column: Int, at point: CGPoint) {
        didHandleLongPressNumber = false
        activeKey = (row, column)
        gestureStartPoint = point
        gestureAnalyzer.reset()
        gestureAnalyzer.addPoint(point)
        gestureDirections = []
        previewVowel = nil
    }

    func gestureEnded(row: Int, column: Int) {
        if didHandleLongPressNumber {
            didHandleLongPressNumber = false
            resetGestureState()
            return
        }

        if isSymbolMode {
            handleSymbolModeTap(row: row, column: column)
        } else {
            handleKoreanModeGesture(row: row, column: column)
        }
        resetGestureState()
    }
}
```

**Step 2: Run test to verify it passes**

Run: `xcodebuild test -scheme MoakiKeyboardTests -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:MoakiKeyboardTests/KeyboardViewModelLongPressTests`  
Expected: PASS.

**Step 3: Commit**

```bash
git add MoakiKeyboard/Views/KeyboardView.swift
git commit -m "fix: suppress gesture-end consonant after long-press number"
```

### Task 3: Route Long-Press Callback Through Dedicated ViewModel API

**Files:**
- Modify: `MoakiKeyboard/Views/KeyboardView.swift`

**Step 1: Wire callback**

```swift
onLongPressNumber: { number in
    viewModel.inputLongPressNumber(number)
},
```

**Step 2: Run focused tests**

Run: `xcodebuild test -scheme MoakiKeyboardTests -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:MoakiKeyboardTests/KeyboardViewModelLongPressTests`  
Expected: PASS.

**Step 3: Commit**

```bash
git add MoakiKeyboard/Views/KeyboardView.swift
git commit -m "refactor: route long-press number via dedicated viewmodel entrypoint"
```

### Task 4: Full Verification And Hotfix Exit Criteria

**Files:**
- Verify only (no file changes expected)

**Step 1: Run project test suite**

Run: `xcodebuild test -scheme MoakiKeyboardTests -destination 'platform=iOS Simulator,name=iPhone 17'`  
Expected: PASS.

**Step 2: Run extension build smoke test**

Run: `xcodebuild -quiet build -scheme MoakiKeyboard -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath /tmp/ios-moaki-derived`  
Expected: BUILD SUCCEEDED.

**Step 3: Manual validation on simulator**

1. Switch to Korean mode.
2. Long press `ㅂ` key.
3. Confirm only `1` is inserted.
4. Tap `ㅂ` normally afterward and confirm consonant input still works.

**Step 4: Final commit**

```bash
git add MoakiKeyboard/Views/KeyboardView.swift MoakiKeyboardTests/KeyboardViewModelLongPressTests.swift
git commit -m "hotfix: prevent duplicate consonant after number-key long press (#15)"
```
