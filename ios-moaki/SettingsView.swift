//
//  SettingsView.swift
//  ios-moaki
//
//  Created for vowel popup mode feature
//

import SwiftUI

/// 호스트 앱의 설정 화면.
/// 모음 팝업 모드 같은, 키보드 익스텐션에서 사용할 설정 토글을 제공.
///
/// ⚠️ 키보드 익스텐션과 메인 앱은 서로 다른 프로세스/sandbox 라서 일반
/// `UserDefaults.standard` 로는 값이 공유되지 않는다. 동기화하려면 App Group
/// entitlement 가 두 타겟에 추가돼 있어야 한다 (`group.com.avabag01.bigmoaki`).
/// entitlement 가 없으면 fallback 으로 standard 에 저장되며, 이 경우 호스트 앱
/// 토글은 호스트 앱 내에서만 유효하다.
struct SettingsView: View {

    private static let appGroupSuite = "group.com.avabag01.bigmoaki"

    private static let useVowelPopupModeKey = "useVowelPopupMode"

    /// App Group 우선, 실패 시 standard 로 fallback.
    private var defaults: UserDefaults {
        UserDefaults(suiteName: Self.appGroupSuite) ?? .standard
    }

    @State private var useVowelPopupMode: Bool = false

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $useVowelPopupMode) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("모음 팝업 모드")
                            .font(.body)
                        Text("자음 키를 누르면 키보드 전체가 모음 팝업으로 바뀝니다. 모음에서 떼면 음절이 입력되고, 자음으로 다시 끌어가면 받침까지 한 번에 입력됩니다.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: useVowelPopupMode) { _, newValue in
                    defaults.set(newValue, forKey: Self.useVowelPopupModeKey)
                }
            } header: {
                Text("입력 방식")
            } footer: {
                Text("끄면 기본 슬라이드 제스처 입력으로 동작합니다.")
            }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            useVowelPopupMode = defaults.bool(forKey: Self.useVowelPopupModeKey)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
