import Foundation
import Combine

class KeyboardSettings: ObservableObject {
    static let shared = KeyboardSettings()

    /// App Group suite for sharing with the host app. If the group is not
    /// configured/entitled, this gracefully falls back to UserDefaults.standard.
    static let appGroupSuite = "group.com.avabag01.bigmoaki"

    private let defaults: UserDefaults

    private enum Keys {
        static let showGesturePreview = "showGesturePreview"
        static let useGridRecognition = "useGridRecognition"
        static let enableLongPressNumber = "enableLongPressNumber"
        static let useVowelPopupMode = "useVowelPopupMode"
    }

    /// 제스처 프리뷰 표시 여부 (기본값: false)
    @Published var showGesturePreview: Bool {
        didSet {
            defaults.set(showGesturePreview, forKey: Keys.showGesturePreview)
        }
    }

    /// 격자(축 분해) 기반 제스처 인식 사용 여부 (기본값: true)
    /// ⚠️ 키보드 익스텐션과 메인 앱은 별도 프로세스라, 인앱 토글로 제어하려면
    /// App Group 공유 UserDefaults(suiteName:)가 필요함. 지금은 익스텐션 자체 기본값을 사용.
    @Published var useGridRecognition: Bool {
        didSet {
            defaults.set(useGridRecognition, forKey: Keys.useGridRecognition)
        }
    }

    /// 자음 길게 누르기 → 숫자 입력 (기본값: false — 누르면 뜨는 모음 힌트/제스처와 충돌해서 끔)
    @Published var enableLongPressNumber: Bool {
        didSet {
            defaults.set(enableLongPressNumber, forKey: Keys.enableLongPressNumber)
        }
    }

    /// 모음 팝업 모드 사용 여부 (기본값: false)
    /// true 면 자음 키를 터치한 순간 키보드 전체가 모음 팝업 레이아웃으로 morph 됩니다.
    /// false 면 기존 슬라이드 제스처 입력을 사용합니다.
    @Published var useVowelPopupMode: Bool {
        didSet {
            defaults.set(useVowelPopupMode, forKey: Keys.useVowelPopupMode)
        }
    }

    private init() {
        // App Group 우선, 실패 시 standard 로 fallback.
        // App Group 이 entitlement 에 추가돼 있어야 호스트 앱 ↔ 키보드 익스텐션 간 동기화됨.
        self.defaults = UserDefaults(suiteName: KeyboardSettings.appGroupSuite) ?? .standard

        // 기본값 등록
        defaults.register(defaults: [
            Keys.showGesturePreview: false,
            Keys.useGridRecognition: true,
            Keys.enableLongPressNumber: false,
            Keys.useVowelPopupMode: false
        ])

        // 저장된 값 로드
        self.showGesturePreview = defaults.bool(forKey: Keys.showGesturePreview)
        self.useGridRecognition = defaults.bool(forKey: Keys.useGridRecognition)
        self.enableLongPressNumber = defaults.bool(forKey: Keys.enableLongPressNumber)
        self.useVowelPopupMode = defaults.bool(forKey: Keys.useVowelPopupMode)
    }
}
