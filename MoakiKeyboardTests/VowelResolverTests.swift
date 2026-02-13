import XCTest
@testable import MoakiKeyboard

final class VowelResolverTests: XCTestCase {

    var resolver: VowelResolver!

    override func setUp() {
        super.setUp()
        resolver = VowelResolver()
    }

    override func tearDown() {
        resolver = nil
        super.tearDown()
    }

    // MARK: - Basic Vowel Tests

    func testBasicVowels() {
        // ㅗ = ↑
        XCTAssertEqual(resolver.resolve(directions: [.up]).vowel, .ㅗ)

        // ㅜ = ↓
        XCTAssertEqual(resolver.resolve(directions: [.down]).vowel, .ㅜ)

        // ㅏ = →
        XCTAssertEqual(resolver.resolve(directions: [.right]).vowel, .ㅏ)

        // ㅓ = ←
        XCTAssertEqual(resolver.resolve(directions: [.left]).vowel, .ㅓ)

        // ㅜ = ↙ (normalizes to ↓)
        XCTAssertEqual(resolver.resolve(directions: [.downLeft]).vowel, .ㅜ)

        // ㅗ = ↖ (normalizes to ↑)
        XCTAssertEqual(resolver.resolve(directions: [.upLeft]).vowel, .ㅗ)
    }

    // MARK: - Y-Vowel Tests (Triple Direction)

    func testYVowels() {
        // ㅛ = ↑↓↑
        XCTAssertEqual(resolver.resolve(directions: [.up, .down, .up]).vowel, .ㅛ)

        // ㅠ = ↓↑↓
        XCTAssertEqual(resolver.resolve(directions: [.down, .up, .down]).vowel, .ㅠ)

        // ㅑ = →←→
        XCTAssertEqual(resolver.resolve(directions: [.right, .left, .right]).vowel, .ㅑ)

        // ㅕ = ←→←
        XCTAssertEqual(resolver.resolve(directions: [.left, .right, .left]).vowel, .ㅕ)
    }

    // MARK: - Y-Vowel Diagonal Drift Tests

    func testYVowelDiagonalDrift() {
        // ㅛ = ↑↓↗ (세 번째 획이 ↗로 빠질 때)
        XCTAssertEqual(resolver.resolve(directions: [.up, .down, .upRight]).vowel, .ㅛ)

        // ㅛ = ↑↘↗ (중간+세 번째 모두 오른쪽 대각선)
        XCTAssertEqual(resolver.resolve(directions: [.up, .downRight, .upRight]).vowel, .ㅛ)

        // ㅠ = ↓↑↘ (세 번째 획이 ↘로 빠질 때)
        XCTAssertEqual(resolver.resolve(directions: [.down, .up, .downRight]).vowel, .ㅠ)

        // ㅠ = ↓↗↘ (중간+세 번째 모두 오른쪽 대각선)
        XCTAssertEqual(resolver.resolve(directions: [.down, .upRight, .downRight]).vowel, .ㅠ)
    }

    // MARK: - Complex Vowel Tests (Diphthongs)

    func testDiphthongs() {
        // ㅘ = ↑→
        XCTAssertEqual(resolver.resolve(directions: [.up, .right]).vowel, .ㅘ)

        // ㅙ = ↑→←
        XCTAssertEqual(resolver.resolve(directions: [.up, .right, .left]).vowel, .ㅙ)

        // ㅝ = ↓←
        XCTAssertEqual(resolver.resolve(directions: [.down, .left]).vowel, .ㅝ)

        // ㅞ = ↓→←
        XCTAssertEqual(resolver.resolve(directions: [.down, .right, .left]).vowel, .ㅞ)

        // ㅚ = ↑↓
        XCTAssertEqual(resolver.resolve(directions: [.up, .down]).vowel, .ㅚ)

        // ㅟ = ↓↑
        XCTAssertEqual(resolver.resolve(directions: [.down, .up]).vowel, .ㅟ)
    }

    // MARK: - Diphthong Diagonal Drift Tests

    func testDiphthongDiagonalDrift() {
        // ㅙ = ↑→↙ (세 번째 획이 ↙로 빠질 때, 정규화 후 ↑→↓)
        XCTAssertEqual(resolver.resolve(directions: [.up, .right, .downLeft]).vowel, .ㅙ)
        XCTAssertEqual(resolver.resolve(directions: [.up, .right, .down]).vowel, .ㅙ)

        // ㅙ = ↑↗← (두 번째 획이 ↗로 빠질 때)
        XCTAssertEqual(resolver.resolve(directions: [.up, .upRight, .left]).vowel, .ㅙ)

        // ㅙ = ↑↗↙ (두 번째/세 번째 획이 모두 대각선으로 빠질 때, 정규화 후 ↑↗↓)
        XCTAssertEqual(resolver.resolve(directions: [.up, .upRight, .downLeft]).vowel, .ㅙ)
        XCTAssertEqual(resolver.resolve(directions: [.up, .upRight, .down]).vowel, .ㅙ)

        // ㅞ = ↓→↙ (세 번째 획이 ↙로 빠질 때, 정규화 후 ↓→↓)
        XCTAssertEqual(resolver.resolve(directions: [.down, .right, .downLeft]).vowel, .ㅞ)
        XCTAssertEqual(resolver.resolve(directions: [.down, .right, .down]).vowel, .ㅞ)

        // ㅞ = ↓↘← (두 번째 획이 ↘로 빠질 때)
        XCTAssertEqual(resolver.resolve(directions: [.down, .downRight, .left]).vowel, .ㅞ)

        // ㅞ = ↓↘↙ (두 번째/세 번째 획이 모두 대각선으로 빠질 때, 정규화 후 ↓↘↓)
        XCTAssertEqual(resolver.resolve(directions: [.down, .downRight, .downLeft]).vowel, .ㅞ)
        XCTAssertEqual(resolver.resolve(directions: [.down, .downRight, .down]).vowel, .ㅞ)
    }

    func testDiphthongDriftDoesNotOverMatch() {
        // ㅘ should remain stable (3번째 위 반전은 ㅙ로 보정하지 않음)
        XCTAssertEqual(resolver.resolve(directions: [.up, .right]).vowel, .ㅘ)
        XCTAssertEqual(resolver.resolve(directions: [.up, .right, .up]).vowel, .ㅘ)
        XCTAssertNotEqual(resolver.resolve(directions: [.up, .right, .up]).vowel, .ㅙ)

        // ㅞ 주변 패턴 과인식 방지 (기존 prefix 매칭 동작은 유지)
        XCTAssertEqual(resolver.resolve(directions: [.down, .right, .up]).vowel, .ㅜ)
        XCTAssertNotEqual(resolver.resolve(directions: [.down, .right, .up]).vowel, .ㅞ)
    }

    // MARK: - Ae/E Vowel Tests

    func testAeEVowels() {
        // ㅐ = →←
        XCTAssertEqual(resolver.resolve(directions: [.right, .left]).vowel, .ㅐ)

        // ㅒ = →←→←
        XCTAssertEqual(resolver.resolve(directions: [.right, .left, .right, .left]).vowel, .ㅒ)

        // ㅔ = ←→
        XCTAssertEqual(resolver.resolve(directions: [.left, .right]).vowel, .ㅔ)

        // ㅖ = ←→←→
        XCTAssertEqual(resolver.resolve(directions: [.left, .right, .left, .right]).vowel, .ㅖ)
    }

    // MARK: - Special Vowels

    func testSpecialVowels() {
        // ㅢ = ↘↗ (ㅡ + ㅣ 대각선)
        XCTAssertEqual(resolver.resolve(directions: [.downRight, .upRight]).vowel, .ㅢ)

        // ㅢ = ↘↑ (ㅡ + 수직 위)
        XCTAssertEqual(resolver.resolve(directions: [.downRight, .up]).vowel, .ㅢ)
    }

    // MARK: - Edge Cases

    func testEmptyDirections() {
        let result = resolver.resolve(directions: [])
        XCTAssertNil(result.vowel)
        XCTAssertFalse(result.hasMoreMatches)
    }

    func testPartialMatch() {
        // ↑ alone matches ㅗ
        let result = resolver.resolve(directions: [.up])
        XCTAssertEqual(result.vowel, .ㅗ)
        // But there could be longer matches (↑→ for ㅘ, ↑↓ for ㅚ, etc.)
        XCTAssertTrue(result.hasMoreMatches)
    }

    func testNoMatch() {
        // ↗ alone doesn't match any pattern as a complete vowel
        // (it's only part of ㅢ = ↙↗)
        let result = resolver.resolve(directions: [.upRight])
        XCTAssertNil(result.vowel)
    }

    // MARK: - Peek Vowel Tests

    func testPeekVowel() {
        // Should return the current matched vowel without consuming
        XCTAssertEqual(resolver.peekVowel(directions: [.up]), .ㅗ)
        XCTAssertEqual(resolver.peekVowel(directions: [.up, .right]), .ㅘ)
        XCTAssertNil(resolver.peekVowel(directions: []))
    }

    // MARK: - Potential Match Tests

    func testHasPotentialMatch() {
        // Single direction that could be part of longer pattern
        XCTAssertTrue(resolver.hasPotentialMatch(directions: [.up])) // Could be ㅗ, ㅘ, ㅙ, ㅚ, ㅛ

        // Direction sequence that doesn't match anything
        XCTAssertFalse(resolver.hasPotentialMatch(directions: [.upRight]))
    }
}
