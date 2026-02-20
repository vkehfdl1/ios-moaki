[한국어](README.md)

# Moaki

> Gesture-based Korean (Hangul) Keyboard

<!-- TODO: Add keyboard demo video -->

## Features

- Swipe on consonant keys to input vowels (all 21 vowels)
- 4-row consonant layout including double consonants
- Long press consonants to input numbers
- Number/symbol keypad
- Dark mode, haptic feedback
- No network required

## Gesture Guide

Drag on a consonant key to input a vowel. Left diagonals (↖, ↙) are normalized to vertical directions.

### Basic Vowels

| Direction | Vowel |
|-----------|-------|
| → | ㅏ (a) |
| ← | ㅓ (eo) |
| ↑ (or ↖) | ㅗ (o) |
| ↓ (or ↙) | ㅜ (u) |
| ↘ | ㅡ (eu) |
| ↗ | ㅣ (i) |

### Y-Vowels (Back-and-forth gestures)

| Direction | Vowel |
|-----------|-------|
| ↑↓↑ | ㅛ (yo) |
| ↓↑↓ | ㅠ (yu) |
| →←→ | ㅑ (ya) |
| ←→← | ㅕ (yeo) |

### Compound Vowels

| Direction | Vowel |
|-----------|-------|
| ↑→ | ㅘ (wa) |
| ↑→← | ㅙ (wae) |
| ↓← | ㅝ (wo) |
| ↓←→ | ㅞ (we) |
| ↑↓ | ㅚ (oe) |
| ↓↑ | ㅟ (wi) |
| →← | ㅐ (ae) |
| →←→← | ㅒ (yae) |
| ←→ | ㅔ (e) |
| ←→←→ | ㅖ (ye) |
| ↘↗ or ↘↑ | ㅢ (ui) |

## Keyboard Layout

```
 ~  ㅃ ㅉ ㄸ ㄲ ㅆ  !
 ^  ㅂ ㅈ ㄷ ㄱ ㅅ  ?
 ;  ㅁ ㄴ ㅇ ㄹ ㅎ  .
 *  ㅋ ㅌ ㅊ ㅍ  ⌫
[Space]  [⏎]  [🌐]
```

Long press consonants for numbers:

```
ㅂ→1  ㅈ→2  ㄷ→3  ㄱ→4  ㅅ→5
ㅁ→6  ㄴ→7  ㅇ→8  ㄹ→9  ㅎ→0
```

## Install (TestFlight)

1. Install [TestFlight](https://apps.apple.com/app/testflight/id899247664) on your iOS device.
2. Tap the invite link below to install Moaki.

> **TestFlight invite link**: [Moaki TestFlight](https://testflight.apple.com/join/zWVF8vqJ)

## Activate the Keyboard

1. **Settings** → **General** → **Keyboard** → **Keyboards** → **Add New Keyboard** → Select **Moaki**
2. Switch to Moaki using the 🌐 button when typing

## Build

```bash
git clone https://github.com/vkehfdl1/ios-moaki.git
cd ios-moaki
open ios-moaki.xcodeproj
```

Select the `MoakiKeyboard` scheme in Xcode and build.

```bash
xcodebuild -scheme MoakiKeyboard -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild test -scheme MoakiKeyboardTests -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Structure

```
ios-moaki/
├── ios-moaki/              # Main app (settings UI)
├── MoakiKeyboard/          # Keyboard extension
│   ├── Engine/             # Hangul composition (HangulComposer, GestureAnalyzer, VowelResolver)
│   ├── Models/             # Data models (HangulJamo, GestureDirection, VowelPattern)
│   ├── Views/              # SwiftUI views (KeyboardView, ConsonantGridView, etc.)
│   ├── Utilities/          # Utilities (HangulConstants, KeyboardMetrics)
│   └── KeyboardViewController.swift
└── MoakiKeyboardTests/     # Unit tests
```

For detailed architecture, see [CLAUDE.md](CLAUDE.md).

## License

[MIT License](LICENSE)
