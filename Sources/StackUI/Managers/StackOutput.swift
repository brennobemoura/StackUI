//
//  File.swift
//
//
//  Created by onnerb on 14/09/22.
//

import UIKit

@MainActor
class StackOutput {

    private weak var viewController: UIViewController?
    private weak var queue: StackQueue?

    private weak var topViewController: UIViewController?
    private weak var referenceConstraint: NSLayoutConstraint?

    weak var delegate: StackOutputDelegate?

    init() {}

    func connect(_ queue: StackQueue, to viewController: UIViewController) {
        self.viewController = viewController
        self.queue = queue

        queue.delegate = self
    }
}

extension StackOutput {

    func offset(by constant: CGFloat) {
        let length = viewController?.view.frame.width ?? .zero
        referenceConstraint?.constant = constant * length
    }

    func layoutIfNeeded() {
        viewController?.view?.layoutIfNeeded()
    }
}

extension StackOutput {

    func insertViewController(
        _ viewController: UIViewController,
        at index: Int = 1,
        offset: CGFloat
    ) -> NSLayoutConstraint? {
        guard let parentViewController = self.viewController else {
            return nil
        }

        parentViewController.addChild(viewController)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        parentViewController.view.insertSubview(viewController.view, at: index)
        viewController.didMove(toParent: parentViewController)

        let referenceConstraint = viewController.view.leadingAnchor.constraint(
            equalTo: parentViewController.view.leadingAnchor,
            constant: parentViewController.view.frame.width * offset
        )

        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: parentViewController.view.topAnchor),
            viewController.view.widthAnchor.constraint(equalTo: parentViewController.view.widthAnchor),
            referenceConstraint,
            viewController.view.bottomAnchor.constraint(equalTo: parentViewController.view.bottomAnchor)
        ])

        return referenceConstraint
    }

    func removeViewController(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
}

extension StackOutput: StackQueueDelegate {

    func push(_ viewController: UIViewController, animated: Bool) async {
        await performPush(viewController, animated: animated)
    }

    func pop(_ viewController: UIViewController, animated: Bool) async {
        await performPop(viewController, animated: animated)
    }

    func insert(_ viewController: UIViewController, at index: Int, animated: Bool) async {
        guard index == delegate?.numberOfViewControllers() else {
            delegate?.outputDidInsertViewController(viewController, at: index)
            return
        }

        await push(viewController, animated: animated)
    }

    func removeAll(animated: Bool) async {
        await performRemoveAll(animated)
    }
}

// MARK: - Animations
private extension StackOutput {

    func perform(
        animated: Bool,
        duration: TimeInterval = 0.3,
        options: UIView.AnimationOptions = .transitionFlipFromRight,
        animations: @escaping () -> Void
    ) async {
        if !animated {
            animations()
            return
        }

        await UIViewPropertyAnimator.perform(
            withDuration: duration,
            delay: .zero,
            options: options,
            animations: animations
        )
    }
}

// MARK: - Erase Animation
private extension StackOutput {

    func performRemoveAll(_ animated: Bool) async {
        viewController?.view.layoutIfNeeded()

        await perform(
            animated: animated,
            options: .curveEaseInOut,
            animations: {
                self.offset(by: 1)
                self.layoutIfNeeded()
            }
        )

        delegate?.outputDidRemoveViewControllers()
    }
}

// MARK: - Push Animation
private extension StackOutput {

    func performPushTransition(
        _ referenceConstraint: NSLayoutConstraint,
        to viewController: UIViewController,
        animated: Bool
    ) async {
        layoutIfNeeded()

        await perform(
            animated: animated && self.topViewController != nil,
            duration: 0.3,
            animations: {
                self.offset(by: -0.4)
                referenceConstraint.constant = .zero
                self.layoutIfNeeded()
            }
        )

        if let viewController = self.topViewController {
            self.removeViewController(viewController)
        }

        self.referenceConstraint = referenceConstraint
        self.topViewController = viewController

        delegate?.outputDidPushViewController(viewController)
    }

    func performPush(
        _ viewController: UIViewController,
        animated: Bool
    ) async {
        delegate?.outputWillPushViewController(viewController)

        guard let referenceConstraint = insertViewController(viewController, offset: 1) else {
            delegate?.outputDidPopViewController(viewController)
            return
        }

        await performPushTransition(
            referenceConstraint,
            to: viewController,
            animated: animated
        )
    }
}

// MARK: - Pop Animation
private extension StackOutput {

    func performPopTransition(
        _ referenceConstraint: NSLayoutConstraint?,
        from viewController: UIViewController,
        to previousViewController: UIViewController?,
        animated: Bool
    ) async {
        layoutIfNeeded()

        await perform(
            animated: animated,
            animations: {
                self.offset(by: 1)
                referenceConstraint?.constant = .zero
                self.layoutIfNeeded()
            }
        )

        self.referenceConstraint = referenceConstraint
        self.topViewController = previousViewController

        self.removeViewController(viewController)

        delegate?.outputDidPopViewController(viewController)
    }

    func prepareForPoping(_ viewController: UIViewController?) -> NSLayoutConstraint? {
        guard let viewController = viewController else {
            return nil
        }

        return insertViewController(viewController, at: .zero, offset: -0.4)
    }

    func performPop(
        _ viewController: UIViewController,
        animated: Bool
    ) async {
        guard delegate?.numberOfViewControllers() ?? .zero > 1 else {
            return
        }

        if viewController !== self.topViewController {
            delegate?.outputDidPopViewController(viewController)
            return
        }

        let previousViewController = delegate?.previousViewController()
        let referenceConstraint = prepareForPoping(previousViewController)

        await performPopTransition(
            referenceConstraint,
            from: viewController,
            to: previousViewController,
            animated: animated
        )
    }
}

// MARK: - Gesture Coordinator
extension StackOutput {

    func makeGestureCoordinator(
        parent parentViewController: UIViewController,
        previous previousViewController: UIViewController
    ) -> StackGestureCoordinator? {
        guard
            let currentViewController = topViewController,
            let referenceConstraint = referenceConstraint,
            let queue = queue
        else { return nil }

        return .init(
            parent: parentViewController,
            current: currentViewController,
            previous: previousViewController,
            reference: referenceConstraint,
            queue: queue,
            delegate: self
        )
    }
}

extension StackOutput: StackGestureDelegate {

    func attachViewController(
        _ viewController: UIViewController,
        at index: Int,
        offset: CGFloat
    ) -> NSLayoutConstraint? {
        insertViewController(
            viewController,
            at: index,
            offset: offset
        )
    }

    func didPopViewController(
        _ viewController: UIViewController,
        _ topViewController: UIViewController,
        referenceConstraint: NSLayoutConstraint
    ) {
        removeViewController(viewController)
        self.topViewController = topViewController
        self.referenceConstraint = referenceConstraint
        delegate?.outputDidPopViewController(viewController)
    }
}
