import Foundation
import Combine

class KeyboardSettings: ObservableObject {
    static let shared = KeyboardSettings()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let showGesturePreview = "showGesturePreview"
    }

    /// 제스처 프리뷰 표시 여부 (기본값: false)
    @Published var showGesturePreview: Bool {
        didSet {
            defaults.set(showGesturePreview, forKey: Keys.showGesturePreview)
        }
    }

    private init() {
        // 기본값 등록
        defaults.register(defaults: [
            Keys.showGesturePreview: false
        ])

        // 저장된 값 로드
        self.showGesturePreview = defaults.bool(forKey: Keys.showGesturePreview)
    }
}
