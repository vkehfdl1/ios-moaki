import XCTest
@testable import MoakiKeyboard

final class HangulComposerTests: XCTestCase {

    var composer: HangulComposer!

    override func setUp() {
        super.setUp()
        composer = HangulComposer()
    }

    override func tearDown() {
        composer = nil
        super.tearDown()
    }

    // MARK: - Basic Composition Tests

    func testInitialState() {
        XCTAssertEqual(composer.state, .empty)
        XCTAssertNil(composer.currentComposingCharacter)
        XCTAssertEqual(composer.displayText, "")
    }

    func testSingleChoseong() {
        _ = composer.inputChoseong(.ㄱ)
        XCTAssertEqual(composer.currentComposingCharacter, "ㄱ")
    }

    func testChoseongJungseong() {
        _ = composer.inputChoseong(.ㄱ)
        _ = composer.inputJungseong(.ㅏ)
        XCTAssertEqual(composer.currentComposingCharacter, "가")
    }

    func testCompleteSyllable() {
        _ = composer.inputChoseong(.ㄱ)
        _ = composer.inputJungseong(.ㅏ)
        _ = composer.inputChoseong(.ㄴ)
        XCTAssertEqual(composer.currentComposingCharacter, "간")
    }

    func testSequentialSyllables() {
        // 안녕
        _ = composer.inputChoseong(.ㅇ)
        _ = composer.inputJungseong(.ㅏ)
        _ = composer.inputChoseong(.ㄴ)
        XCTAssertEqual(composer.currentComposingCharacter, "안")

        _ = composer.inputJungseong(.ㅕ)
        XCTAssertEqual(composer.composedText, "아")
        XCTAssertEqual(composer.currentComposingCharacter, "녀")

        _ = composer.inputChoseong(.ㅇ)
        XCTAssertEqual(composer.currentComposingCharacter, "녕")
    }

    // MARK: - Double Jongseong Tests

    func testDoubleJongseong() {
        // 값
        _ = composer.inputChoseong(.ㄱ)
        _ = composer.inputJungseong(.ㅏ)
        _ = composer.inputChoseong(.ㅂ)
        _ = composer.inputChoseong(.ㅅ)
        XCTAssertEqual(composer.currentComposingCharacter, "값")
    }

    func testDoubleJongseongSplit() {
        // 읽다 -> 읽 + 다
        _ = composer.inputChoseong(.ㅇ)
        _ = composer.inputJungseong(.ㅣ)
        _ = composer.inputChoseong(.ㄹ)
        _ = composer.inputChoseong(.ㄱ)
        XCTAssertEqual(composer.currentComposingCharacter, "읽")

        _ = composer.inputJungseong(.ㅏ)
        XCTAssertEqual(composer.composedText, "일")
        XCTAssertEqual(composer.currentComposingCharacter, "가")
    }

    // MARK: - Delete Tests

    func testDeleteChoseong() {
        _ = composer.inputChoseong(.ㄱ)
        _ = composer.deleteBackward()
        XCTAssertEqual(composer.state, .empty)
        XCTAssertNil(composer.currentComposingCharacter)
    }

    func testDeleteJungseong() {
        _ = composer.inputChoseong(.ㄱ)
        _ = composer.inputJungseong(.ㅏ)
        _ = composer.deleteBackward()
        XCTAssertEqual(composer.currentComposingCharacter, "ㄱ")
    }

    func testDeleteJongseong() {
        _ = composer.inputChoseong(.ㄱ)
        _ = composer.inputJungseong(.ㅏ)
        _ = composer.inputChoseong(.ㄴ)
        _ = composer.deleteBackward()
        XCTAssertEqual(composer.currentComposingCharacter, "가")
    }

    func testDeleteDoubleJongseong() {
        _ = composer.inputChoseong(.ㄱ)
        _ = composer.inputJungseong(.ㅏ)
        _ = composer.inputChoseong(.ㅂ)
        _ = composer.inputChoseong(.ㅅ)
        XCTAssertEqual(composer.currentComposingCharacter, "값")

        _ = composer.deleteBackward()
        XCTAssertEqual(composer.currentComposingCharacter, "갑")
    }

    // MARK: - Edge Cases

    func testDoubleConsonantCannotBeJongseong() {
        // ㄸ, ㅃ, ㅉ cannot be jongseong
        _ = composer.inputChoseong(.ㄱ)
        _ = composer.inputJungseong(.ㅏ)
        _ = composer.inputChoseong(.ㄸ)

        XCTAssertEqual(composer.composedText, "가")
        XCTAssertEqual(composer.currentComposingCharacter, "ㄸ")
    }

    func testVowelWithoutConsonant() {
        _ = composer.inputJungseong(.ㅏ)
        XCTAssertEqual(composer.composedText, "ㅏ")
        XCTAssertEqual(composer.state, .empty)
    }

    // MARK: - Unicode Composition Tests

    func testUnicodeValues() {
        // 가 = 0xAC00
        _ = composer.inputChoseong(.ㄱ)
        _ = composer.inputJungseong(.ㅏ)
        XCTAssertEqual(composer.currentComposingCharacter?.unicodeScalars.first?.value, 0xAC00)

        // 힣 = 0xD7A3 (last syllable)
        composer.reset()
        _ = composer.inputChoseong(.ㅎ)
        _ = composer.inputJungseong(.ㅣ)
        _ = composer.inputChoseong(.ㅎ)
        XCTAssertEqual(composer.currentComposingCharacter?.unicodeScalars.first?.value, 0xD7A3)
    }

    // MARK: - Complex Input Sequences

    func testHelloWorld() {
        // 안녕하세요
        let inputs: [(Choseong?, Jungseong?)] = [
            (.ㅇ, .ㅏ), (nil, nil), // 아 + ㄴ (next)
            (.ㄴ, nil), // attached as jongseong
            (nil, .ㅕ), // splits to 안 + 녀
            (.ㅇ, nil), // 녕
            (nil, nil), // commit
            (.ㅎ, .ㅏ), // 하
            (.ㅅ, nil), // 세 (next syllable start)
            (nil, .ㅔ), // 세
            (.ㅇ, nil), // jongseong? no, starts new: 세 + ㅇ
            (nil, .ㅛ), // 셍? no - 세요
        ]

        // Simplified test
        _ = composer.inputChoseong(.ㅇ)
        _ = composer.inputJungseong(.ㅏ)
        _ = composer.inputChoseong(.ㄴ)
        _ = composer.inputJungseong(.ㅕ)
        _ = composer.inputChoseong(.ㅇ)

        composer.commitCurrent()

        _ = composer.inputChoseong(.ㅎ)
        _ = composer.inputJungseong(.ㅏ)

        composer.commitCurrent()

        _ = composer.inputChoseong(.ㅅ)
        _ = composer.inputJungseong(.ㅔ)

        composer.commitCurrent()

        _ = composer.inputChoseong(.ㅇ)
        _ = composer.inputJungseong(.ㅛ)

        composer.commitCurrent()

        XCTAssertEqual(composer.composedText, "안녕하세요")
    }

    func testThankYou() {
        // 감사합니다
        _ = composer.inputChoseong(.ㄱ)
        _ = composer.inputJungseong(.ㅏ)
        _ = composer.inputChoseong(.ㅁ)
        _ = composer.inputJungseong(.ㅏ)

        XCTAssertEqual(composer.composedText, "가")

        _ = composer.inputChoseong(.ㅅ)
        _ = composer.inputJungseong(.ㅏ)

        XCTAssertEqual(composer.composedText, "감")

        _ = composer.inputChoseong(.ㅎ)
        _ = composer.inputJungseong(.ㅏ)

        XCTAssertEqual(composer.composedText, "감사")

        _ = composer.inputChoseong(.ㅂ)
        _ = composer.inputJungseong(.ㅣ)

        XCTAssertEqual(composer.composedText, "감사하")

        _ = composer.inputChoseong(.ㄴ)
        _ = composer.inputJungseong(.ㅏ)

        XCTAssertEqual(composer.composedText, "감사합")

        _ = composer.inputChoseong(.ㄷ)
        _ = composer.inputJungseong(.ㅏ)

        composer.commitCurrent()

        XCTAssertEqual(composer.composedText, "감사합니다")
    }
}
