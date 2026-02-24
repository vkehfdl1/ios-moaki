import XCTest
@testable import MoakiKeyboard

final class KeyboardViewModelLongPressTests: XCTestCase {
    private var viewModel: KeyboardViewModel!
    private var delegate: SpyKeyboardDelegate!

    override func setUp() {
        super.setUp()
        viewModel = KeyboardViewModel()
        delegate = SpyKeyboardDelegate()
        viewModel.delegate = delegate
    }

    override func tearDown() {
        viewModel = nil
        delegate = nil
        super.tearDown()
    }

    func testLongPressNumberThenGestureEnd_insertsOnlyNumber() {
        viewModel.gestureStarted(row: 1, column: 1, at: .zero) // ㅂ key
        viewModel.inputLongPressNumber("1")
        viewModel.gestureEnded(row: 1, column: 1)

        XCTAssertEqual(delegate.insertedTexts, ["1"])
        XCTAssertTrue(delegate.composingUpdates.isEmpty)
    }

    func testNormalTapStillInputsConsonant() {
        viewModel.gestureStarted(row: 1, column: 1, at: .zero) // ㅂ key
        viewModel.gestureEnded(row: 1, column: 1)

        XCTAssertEqual(delegate.insertedTexts, [])
        XCTAssertEqual(delegate.composingUpdates.last?.current, "ㅂ")
    }

    func testLongPressSuppressionResetsForNextGesture() {
        viewModel.gestureStarted(row: 1, column: 1, at: .zero)
        viewModel.inputLongPressNumber("1")
        viewModel.gestureEnded(row: 1, column: 1)

        viewModel.gestureStarted(row: 1, column: 2, at: .zero) // ㅈ key
        viewModel.gestureEnded(row: 1, column: 2)

        XCTAssertEqual(delegate.insertedTexts, ["1"])
        XCTAssertEqual(delegate.composingUpdates.last?.current, "ㅈ")
    }
}

private final class SpyKeyboardDelegate: KeyboardViewModelDelegate {
    struct ComposingUpdate: Equatable {
        let previous: String
        let current: String
    }

    var insertedTexts: [String] = []
    var deleteCount = 0
    var composingUpdates: [ComposingUpdate] = []
    var switchKeyboardCount = 0
    var hapticCount = 0

    func insertText(_ text: String) {
        insertedTexts.append(text)
    }

    func deleteBackward() {
        deleteCount += 1
    }

    func updateComposingText(from previous: String, to current: String) {
        composingUpdates.append(.init(previous: previous, current: current))
    }

    func switchToNextKeyboard() {
        switchKeyboardCount += 1
    }

    func triggerHapticFeedback() {
        hapticCount += 1
    }
}
