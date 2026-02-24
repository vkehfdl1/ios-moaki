# HotFix #15 Number Keypad Long-Press Design

**Date:** 2026-02-24  
**Issue:** `#15` Number keypad long press display bug  
**Reported behavior:** Long-pressing `ㅂ` inserts `1` and then also inserts `ㅂ` (`1ㅂ`).

## Problem Statement

Long press on mapped Korean consonant keys should produce only the mapped number.  
Current behavior inserts the number on long press and then inserts the consonant on touch end.

## Root Cause Summary

Current event flow:

1. `KeyView.startLongPressTimer()` fires and calls `onLongPress?(number)` after 0.5s.
2. `KeyboardView` handles that callback by calling `viewModel.inputNumber(number)`.
3. On finger release, `KeyView` always calls `onGestureEnd()`.
4. `KeyboardViewModel.gestureEnded(...)` treats the same interaction as a normal Korean key gesture and inputs consonant `ㅂ` when directions are empty.

Result: number + consonant for one long-press gesture.

## Assumptions For This Hotfix

- Long press on mapped Korean keys inserts number only.
- The follow-up touch-end event for that same gesture must not insert consonant.
- Normal tap and drag-to-vowel behavior remains unchanged.

## Approaches

### 1) Consume touch-end in `KeyView`

- Add local state in `KeyView` to skip `onGestureEnd()` after long press.
- Pros: Fix is close to gesture source.
- Cons: Harder to unit test in current XCTest setup (SwiftUI gesture/timer behavior).

### 2) Suppress next `gestureEnded` in `KeyboardViewModel` (Recommended)

- Add a view-model flag for "long press number already handled for active gesture".
- Route long-press callback through a dedicated view-model API that sets the flag.
- `gestureEnded` early-returns when flag is set.
- Pros: Minimal surface change, testable via unit tests without UI harness.
- Cons: Requires small state coordination in view model.

### 3) Refactor key interaction into explicit event enum

- Replace multiple callbacks with single `KeyInteractionResult` (`tap`, `gesture`, `longPressNumber`, `backspacePress`).
- Pros: Best long-term clarity.
- Cons: Too large for hotfix scope, higher regression risk.

## Recommended Design

Use approach 2.

- Add `didHandleLongPressNumber` state in `KeyboardViewModel`.
- Add `inputLongPressNumber(_:)` in `KeyboardViewModel`:
  - Set `didHandleLongPressNumber = true`
  - Reuse existing `inputNumber(_:)`
- In `gestureStarted(...)`, reset the flag to `false`.
- In `gestureEnded(...)`, if flag is true:
  - Reset flag
  - Call `resetGestureState()`
  - Return without consonant/symbol processing.
- In `KeyboardView`, route `onLongPressNumber` to `viewModel.inputLongPressNumber(...)` instead of `inputNumber(...)`.

## Test Strategy

- Add dedicated unit tests for `KeyboardViewModel` long-press behavior:
  - Long press number + gesture end inserts only number.
  - Normal tap still inserts consonant.
  - Suppression applies only to the long-press gesture and clears for the next gesture.

## Acceptance Criteria

- Repro case: long press `ㅂ` inserts `1` only (no trailing `ㅂ`).
- No regressions in normal consonant tap or vowel gesture behavior.
- Unit tests covering the above behavior pass in `MoakiKeyboardTests`.
