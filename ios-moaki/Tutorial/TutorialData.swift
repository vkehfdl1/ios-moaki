import Foundation

struct VowelGesture: Identifiable {
    let id = UUID()
    let vowel: String
    let directions: [String]
    let label: String
    var altDirections: [String]? = nil
    var altLabel: String? = nil
}

struct TutorialStage: Identifiable {
    let id: Int
    let title: String
    let description: String
    let vowelGestures: [VowelGesture]
    let practiceLines: [String]
    let isSentenceMode: Bool

    init(
        id: Int,
        title: String,
        description: String,
        vowelGestures: [VowelGesture] = [],
        practiceLines: [String] = [],
        isSentenceMode: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.vowelGestures = vowelGestures
        self.practiceLines = practiceLines
        self.isSentenceMode = isSentenceMode
    }
}

enum TutorialContent {
    static let stages: [TutorialStage] = [
        // Stage 0: Welcome
        TutorialStage(
            id: 0,
            title: "모아키에 오신 걸 환영합니다",
            description: "모아키는 자음 키를 누르고 슬라이드하여 모음을 입력하는 제스처 기반 한글 키보드입니다.\n\n자음 키 위에서 방향을 바꿔가며 드래그하면 다양한 모음을 조합할 수 있습니다."
        ),

        // Stage 1: Basic Vowels
        TutorialStage(
            id: 1,
            title: "기본 모음",
            description: "자음 키를 누른 채로 상하좌우로 슬라이드하세요.\n왼쪽 대각선(↖↙)은 위/아래로 자동 정규화됩니다.",
            vowelGestures: [
                VowelGesture(vowel: "ㅏ", directions: ["→"], label: "오른쪽"),
                VowelGesture(vowel: "ㅓ", directions: ["←"], label: "왼쪽"),
                VowelGesture(vowel: "ㅗ", directions: ["↑"], label: "위", altDirections: ["↖"], altLabel: "왼쪽 위 대각선"),
                VowelGesture(vowel: "ㅜ", directions: ["↓"], label: "아래", altDirections: ["↙"], altLabel: "왼쪽 아래 대각선"),
            ],
            practiceLines: [
                "가나다라마바사",
                "거너더러머버서",
                "고노도로모보소",
                "구누두루무부수",
            ]
        ),

        // Stage 2: Y-Vowels
        TutorialStage(
            id: 2,
            title: "Y-모음 (왕복 제스처)",
            description: "같은 축을 왕복하면 Y-모음이 됩니다.",
            vowelGestures: [
                VowelGesture(vowel: "ㅑ", directions: ["→", "←", "→"], label: "오른쪽-왼쪽-오른쪽"),
                VowelGesture(vowel: "ㅕ", directions: ["←", "→", "←"], label: "왼쪽-오른쪽-왼쪽"),
                VowelGesture(vowel: "ㅛ", directions: ["↑", "↓", "↑"], label: "위-아래-위"),
                VowelGesture(vowel: "ㅠ", directions: ["↓", "↑", "↓"], label: "아래-위-아래"),
            ],
            practiceLines: [
                "갸냐댜랴먀뱌샤",
                "겨녀뎌려며벼셔",
                "교뇨됴료묘뵤쇼",
                "규뉴듀류뮤뷰슈",
            ]
        ),

        // Stage 3: ㅡ and ㅣ
        TutorialStage(
            id: 3,
            title: "ㅡ와 ㅣ",
            description: "오른쪽 대각선으로 슬라이드하면 ㅡ와 ㅣ가 됩니다.\n\n왼쪽 대각선(↖↙)은 ㅗ/ㅜ로 정규화되지만, 오른쪽 대각선(↗↘)은 별도의 모음입니다.",
            vowelGestures: [
                VowelGesture(vowel: "ㅣ", directions: ["↗"], label: "오른쪽 위 대각선"),
                VowelGesture(vowel: "ㅡ", directions: ["↘"], label: "오른쪽 아래 대각선"),
            ],
            practiceLines: [
                "기니디리미비시",
                "그느드르므브스",
            ]
        ),

        // Stage 4: Compound Vowels - ㅘ ㅝ ㅚ ㅟ
        TutorialStage(
            id: 4,
            title: "복합 모음 (1)",
            description: "ㅗ(↑)와 ㅜ(↓)에서 이어서 슬라이드하면 복합 모음이 됩니다.",
            vowelGestures: [
                VowelGesture(vowel: "ㅘ", directions: ["↑", "→"], label: "위-오른쪽"),
                VowelGesture(vowel: "ㅝ", directions: ["↓", "←"], label: "아래-왼쪽"),
                VowelGesture(vowel: "ㅚ", directions: ["↑", "↓"], label: "위-아래"),
                VowelGesture(vowel: "ㅟ", directions: ["↓", "↑"], label: "아래-위"),
            ],
            practiceLines: [
                "과궈괴귀",
                "화훠회휘",
            ]
        ),

        // Stage 5: Compound Vowels - ㅐ ㅔ
        TutorialStage(
            id: 5,
            title: "복합 모음 (2)",
            description: "좌우 왕복 한 번이면 ㅐ와 ㅔ가 됩니다.",
            vowelGestures: [
                VowelGesture(vowel: "ㅐ", directions: ["→", "←"], label: "오른쪽-왼쪽"),
                VowelGesture(vowel: "ㅔ", directions: ["←", "→"], label: "왼쪽-오른쪽"),
            ],
            practiceLines: [
                "개게내네대데",
                "래레매메배베",
            ]
        ),

        // Stage 6: Compound Vowels - ㅒ ㅖ
        TutorialStage(
            id: 6,
            title: "복합 모음 (3)",
            description: "ㅐ/ㅔ를 두 번 왕복하면 ㅒ/ㅖ가 됩니다.",
            vowelGestures: [
                VowelGesture(vowel: "ㅒ", directions: ["→", "←", "→", "←"], label: "오른쪽-왼쪽-오른쪽-왼쪽"),
                VowelGesture(vowel: "ㅖ", directions: ["←", "→", "←", "→"], label: "왼쪽-오른쪽-왼쪽-오른쪽"),
            ],
            practiceLines: [
                "걔계",
            ]
        ),

        // Stage 7: Compound Vowels - ㅙ ㅞ
        TutorialStage(
            id: 7,
            title: "복합 모음 (4)",
            description: "ㅘ/ㅝ 끝에서 한 번 더 꺾으면 ㅙ/ㅞ가 됩니다.",
            vowelGestures: [
                VowelGesture(vowel: "ㅙ", directions: ["↑", "→", "←"], label: "위-오른쪽-왼쪽"),
                VowelGesture(vowel: "ㅞ", directions: ["↓", "→", "←"], label: "아래-오른쪽-왼쪽"),
            ],
            practiceLines: [
                "왜웨",
            ]
        ),

        // Stage 8: Compound Vowels - ㅢ
        TutorialStage(
            id: 8,
            title: "복합 모음 (5)",
            description: "오른쪽 아래로 슬라이드한 뒤 왼쪽 위로 올리면 ㅢ가 됩니다.",
            vowelGestures: [
                VowelGesture(vowel: "ㅢ", directions: ["↘", "↖"], label: "오른쪽아래-왼쪽위"),
            ],
            practiceLines: [
                "긔늬듸릐믜",
            ]
        ),

        // Stage 9: Sentence Practice
        TutorialStage(
            id: 9,
            title: "문장 연습",
            description: "지금까지 배운 모든 제스처를 활용해 문장을 입력해보세요.",
            practiceLines: [
                "나라의 말이",
                "중국과 달라",
                "서로 통하지 아니하므로",
            ],
            isSentenceMode: true
        ),
    ]
}
