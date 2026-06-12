import SwiftUI
import Combine

/// 떨어지는 단어 받아치기 게임. 위에서 단어가 떨어지고, 입력해서 맞히면 점수.
/// 바닥에 닿으면 라이프 감소. 진행할수록 빨라짐.
/// (입력은 현재 시스템 키보드 — 키보드 코드 공유 후 모아키 키보드로 교체 예정)
struct FallingWordsGameView: View {
    private struct FallingWord: Identifiable {
        let id = UUID()
        let text: String
        var y: CGFloat
        let x: CGFloat
    }

    @State private var words: [FallingWord] = []
    @State private var input = ""
    @State private var score = 0
    @State private var lives = 3
    @State private var isPlaying = false
    @State private var fallSpeed: CGFloat = 1.2
    @State private var spawnCounter = 0

    private let wordPool = ["안녕", "감사", "사랑", "행복", "친구",
                            "학교", "가족", "음식", "여행", "노래",
                            "바다", "하늘", "사과", "기차", "구름"]
    private let tick = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                // 떨어지는 단어들
                ForEach(words) { word in
                    Text(word.text)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 0.282, green: 0.651, blue: 0.635)))
                        .position(x: word.x, y: word.y)
                }

                // 상단 HUD
                VStack {
                    HStack {
                        Text("점수 \(score)").font(.headline)
                        Spacer()
                        Text(String(repeating: "♥", count: max(0, lives))).foregroundColor(.red)
                    }
                    .padding(.horizontal, 20).padding(.top, 12)
                    Spacer()
                }

                // 시작 / 게임오버 오버레이
                if !isPlaying {
                    VStack(spacing: 18) {
                        Text(lives <= 0 ? "게임 오버" : "떨어지는 단어")
                            .font(.largeTitle).bold()
                        if lives <= 0 { Text("점수 \(score)").font(.title2).foregroundColor(.secondary) }
                        Button(action: startGame) {
                            Text(lives <= 0 ? "다시" : "시작")
                                .font(.headline).foregroundColor(.white)
                                .padding(.horizontal, 40).padding(.vertical, 14)
                                .background(Capsule().fill(Color(red: 0.282, green: 0.651, blue: 0.635)))
                        }
                    }
                    .padding(28)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemGray6)))
                }

                // 입력란 (임시: 시스템 키보드 — 공유 후 모아키로 교체)
                VStack {
                    Spacer()
                    TextField("단어 입력 (임시 시스템 키보드)", text: $input)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .padding()
                        .onChange(of: input) { _, newValue in checkMatch(newValue) }
                }
            }
            .onReceive(tick) { _ in step(height: geo.size.height, width: geo.size.width) }
        }
        .navigationTitle("연습 게임")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func startGame() {
        words = []; score = 0; lives = 3; input = ""; fallSpeed = 1.2; spawnCounter = 0
        isPlaying = true
    }

    private func step(height: CGFloat, width: CGFloat) {
        guard isPlaying else { return }
        for i in words.indices { words[i].y += fallSpeed }

        let bottom = height - 90
        let fallenCount = words.filter { $0.y >= bottom }.count
        if fallenCount > 0 {
            lives -= fallenCount
            words.removeAll { $0.y >= bottom }
            if lives <= 0 { isPlaying = false }
        }

        spawnCounter += 1
        if spawnCounter >= 40 {
            spawnCounter = 0
            let text = wordPool.randomElement() ?? "단어"
            let x = CGFloat.random(in: 60...(max(120, width - 60)))
            words.append(FallingWord(text: text, y: 40, x: x))
            fallSpeed += 0.04
        }
    }

    private func checkMatch(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let idx = words.firstIndex(where: { $0.text == trimmed }) {
            words.remove(at: idx)
            score += 10
            input = ""
        }
    }
}

#Preview {
    NavigationStack { FallingWordsGameView() }
}
