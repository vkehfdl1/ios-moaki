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

        // ㅡ = ↙
        XCTAssertEqual(resolver.resolve(directions: [.downLeft]).vowel, .ㅡ)

        // ㅣ = ↖
        XCTAssertEqual(resolver.resolve(directions: [.upLeft]).vowel, .ㅣ)
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

    // MARK: - Complex Vowel Tests (Diphthongs)

    func testDiphthongs() {
        // ㅘ = ↑→
        XCTAssertEqual(resolver.resolve(directions: [.up, .right]).vowel, .ㅘ)

        // ㅙ = ↑→←
        XCTAssertEqual(resolver.resolve(directions: [.up, .right, .left]).vowel, .ㅙ)

        // ㅝ = ↓→
        XCTAssertEqual(resolver.resolve(directions: [.down, .right]).vowel, .ㅝ)

        // ㅞ = ↓→←
        XCTAssertEqual(resolver.resolve(directions: [.down, .right, .left]).vowel, .ㅞ)

        // ㅚ = ↑↓
        XCTAssertEqual(resolver.resolve(directions: [.up, .down]).vowel, .ㅚ)

        // ㅟ = ↓↑
        XCTAssertEqual(resolver.resolve(directions: [.down, .up]).vowel, .ㅟ)
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
        // ㅢ = ↙↗
        XCTAssertEqual(resolver.resolve(directions: [.downLeft, .upRight]).vowel, .ㅢ)
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
