//
//  ContentView.swift
//  ios-moaki
//
//  Created by Jeffrey Kim on 2026/1/28.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("모아키")
                        .font(.system(size: 48, weight: .bold))

                    Text("Moaki Korean Keyboard")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                // Description
                VStack(spacing: 12) {
                    Text("슬라이드 제스처로 빠르게 한글을 입력하세요")
                        .font(.body)
                        .multilineTextAlignment(.center)

                    Text("자음 키를 누르고 슬라이드하면 모음이 입력됩니다")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Setup Instructions
                VStack(alignment: .leading, spacing: 16) {
                    Text("키보드 활성화 방법")
                        .font(.headline)

                    SetupStepView(
                        number: 1,
                        title: "설정 앱 열기",
                        description: "아래 버튼을 눌러 설정으로 이동하세요"
                    )

                    SetupStepView(
                        number: 2,
                        title: "키보드 추가",
                        description: "일반 → 키보드 → 키보드 → 새 키보드 추가"
                    )

                    SetupStepView(
                        number: 3,
                        title: "모아키 선택",
                        description: "목록에서 '모아키'를 찾아 선택하세요"
                    )

                    SetupStepView(
                        number: 4,
                        title: "키보드 전환",
                        description: "키보드 사용 중 🌐 버튼을 눌러 모아키로 전환"
                    )
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 16)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    NavigationLink {
                        TutorialContainerView()
                    } label: {
                        HStack {
                            Image(systemName: "graduationcap")
                            Text("키보드 튜토리얼 시작")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                    }

                    Button(action: openSettings) {
                        HStack {
                            Image(systemName: "gear")
                            Text("설정 열기")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 1.5)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct SetupStepView: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.blue))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
