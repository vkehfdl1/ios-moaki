import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {

    private var keyboardView: UIHostingController<KeyboardView>?
    private let viewModel = KeyboardViewModel()
    private var feedbackGenerator: UIImpactFeedbackGenerator?

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

        viewModel.delegate = self
        setupKeyboardView()
        setupHapticFeedback()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        keyboardView?.view.frame = view.bounds
    }

    private func setupKeyboardView() {
        let hostingController = UIHostingController(rootView: KeyboardView(viewModel: viewModel))
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
        // Called after the text has changed
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
