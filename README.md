[English](README_en.md)

# 모아키 (Moaki)

> 제스처 기반 한글 키보드

<!-- TODO: 키보드 사용 영상 추가 -->

## 기능

- 자음 키 위 스와이프로 모음 입력 (21종)
- 쌍자음 포함 4줄 자음 배열
- 자음 길게 누르면 숫자 입력
- 숫자/기호 키패드
- 다크모드, 햅틱 피드백
- 네트워크 불필요

## 제스처 가이드

자음 키 위에서 드래그하여 모음을 입력합니다. 왼쪽 대각선(↖, ↙)은 수직 방향으로 정규화됩니다.

### 기본 모음

| 방향 | 모음 |
|------|------|
| → | ㅏ |
| ← | ㅓ |
| ↑ (또는 ↖) | ㅗ |
| ↓ (또는 ↙) | ㅜ |
| ↘ | ㅡ |
| ↗ | ㅣ |

### Y-모음 (왕복 제스처)

| 방향 | 모음 |
|------|------|
| ↑↓↑ | ㅛ |
| ↓↑↓ | ㅠ |
| →←→ | ㅑ |
| ←→← | ㅕ |

### 복합 모음

| 방향 | 모음 |
|------|------|
| ↑→ | ㅘ |
| ↑→← | ㅙ |
| ↓← | ㅝ |
| ↓←→ | ㅞ |
| ↑↓ | ㅚ |
| ↓↑ | ㅟ |
| →← | ㅐ |
| →←→← | ㅒ |
| ←→ | ㅔ |
| ←→←→ | ㅖ |
| ↘↗ 또는 ↘↑ | ㅢ |

## 키보드 배열

```
 ~  ㅃ ㅉ ㄸ ㄲ ㅆ  !
 ^  ㅂ ㅈ ㄷ ㄱ ㅅ  ?
 ;  ㅁ ㄴ ㅇ ㄹ ㅎ  .
 *  ㅋ ㅌ ㅊ ㅍ  ⌫
[스페이스]  [⏎]  [🌐]
```

자음 길게 누르면 숫자 입력:

```
ㅂ→1  ㅈ→2  ㄷ→3  ㄱ→4  ㅅ→5
ㅁ→6  ㄴ→7  ㅇ→8  ㄹ→9  ㅎ→0
```

## 설치 (TestFlight)

1. iOS 기기에서 [TestFlight](https://apps.apple.com/app/testflight/id899247664)를 설치합니다.
2. 아래 초대 링크를 클릭하여 모아키를 설치합니다.

> **TestFlight 초대 링크**: <!-- TODO: TestFlight 초대 링크 추가 -->

## 키보드 활성화

1. **설정** → **일반** → **키보드** → **키보드** → **새 키보드 추가** → **Moaki** 선택
2. 텍스트 입력 시 🌐 버튼으로 모아키로 전환

## 빌드

```bash
git clone https://github.com/vkehfdl1/ios-moaki.git
cd ios-moaki
open ios-moaki.xcodeproj
```

Xcode에서 `MoakiKeyboard` 스킴을 선택하고 빌드합니다.

```bash
xcodebuild -scheme MoakiKeyboard -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild test -scheme MoakiKeyboardTests -destination 'platform=iOS Simulator,name=iPhone 16'
```

## 구조

```
ios-moaki/
├── ios-moaki/              # 메인 앱 (설정 UI)
├── MoakiKeyboard/          # 키보드 익스텐션
│   ├── Engine/             # 한글 조합 (HangulComposer, GestureAnalyzer, VowelResolver)
│   ├── Models/             # 데이터 모델 (HangulJamo, GestureDirection, VowelPattern)
│   ├── Views/              # SwiftUI 뷰 (KeyboardView, ConsonantGridView 등)
│   ├── Utilities/          # 유틸리티 (HangulConstants, KeyboardMetrics)
│   └── KeyboardViewController.swift
└── MoakiKeyboardTests/     # 유닛 테스트
```

자세한 아키텍처는 [CLAUDE.md](CLAUDE.md)를 참조하세요.

## 라이선스

[MIT License](LICENSE)
