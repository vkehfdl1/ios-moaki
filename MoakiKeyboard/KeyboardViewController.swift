import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {

    private var keyboardView: UIViewController?
    private let viewModel = KeyboardViewModel()
    private var feedbackGenerator: UIImpactFeedbackGenerator?
    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        // 키보드 높이 설정 (iOS 키보드 익스텐션은 명시적 높이 필요)
        let heightConstraint = NSLayoutConstraint(
            item: view!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1.0,
            constant: 260
        )
        heightConstraint.priority = .required
        view.addConstraint(heightConstraint)
        self.heightConstraint = heightConstraint

        viewModel.delegate = self
        setupKeyboardView()
        setupHapticFeedback()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        heightConstraint?.constant = 260
        heightConstraint?.isActive = true
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Force UIHostingController to re-enable touch delivery.
        // After keyboard extension lifecycle transitions, the hosting view
        // can lose touch responsiveness. Toggling isUserInteractionEnabled
        // forces UIKit to re-attach the gesture recognizer hierarchy.
        if let hostingView = keyboardView?.view {
            hostingView.isUserInteractionEnabled = false
            hostingView.isUserInteractionEnabled = true
        }

        // Reset any stuck gesture state (e.g., user was mid-drag when backgrounding)
        viewModel.resetGestureState()
    }

    private func setupKeyboardView() {
        let rootView = KeyboardView(viewModel: viewModel).ignoresSafeArea(.all)
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        keyboardView = hostingController
    }

    private func setupHapticFeedback() {
        feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator?.prepare()
    }

    override func textWillChange(_ textInput: UITextInput?) {
        // Called when the text is about to change
    }

    override func textDidChange(_ textInput: UITextInput?) {
        // Reset composer state when text field is cleared externally
        // (e.g., when user sends a message and the app clears the input field)
        // Only reset if the text field is completely empty
        if textDocumentProxy.documentContextBeforeInput == nil &&
           textDocumentProxy.documentContextAfterInput == nil {
            viewModel.resetComposer()
        }
    }
}

// MARK: - KeyboardViewModelDelegate
extension KeyboardViewController: KeyboardViewModelDelegate {
    func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
    }

    func deleteBackward() {
        textDocumentProxy.deleteBackward()
    }

    func updateComposingText(from previous: String, to current: String) {
        // iOS keyboard extensions don't support marked text directly,
        // so we simulate it by deleting the previous composing text
        // and inserting the new composing text.

        // Delete previous composing characters
        for _ in previous {
            textDocumentProxy.deleteBackward()
        }

        // Insert new composing characters
        if !current.isEmpty {
            textDocumentProxy.insertText(current)
        }
    }

    func switchToNextKeyboard() {
        advanceToNextInputMode()
    }

    func triggerHapticFeedback() {
        feedbackGenerator?.impactOccurred()
        feedbackGenerator?.prepare()
    }
}
