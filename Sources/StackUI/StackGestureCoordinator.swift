//
//  StackGestureCoordinator.swift
//
//
//  Created by onnerb on 14/09/22.
//

import UIKit

@MainActor
class StackGestureCoordinator {

    private weak var parentViewController: UIViewController?
    private let currentViewController: UIViewController
    private let previousViewController: UIViewController

    private weak var referenceCurrentConstraint: NSLayoutConstraint?
    private weak var referencePreviousConstraint: NSLayoutConstraint?

    private weak var queue: StackQueue?
    private weak var delegate: StackGestureDelegate?

    init(
        parent parentViewController: UIViewController,
        current currentViewController: UIViewController,
        previous previousViewController: UIViewController,
        reference referenceConstraint: NSLayoutConstraint,
        queue: StackQueue,
        delegate: StackGestureDelegate
    ) {
        self.parentViewController = parentViewController
        self.currentViewController = currentViewController
        self.previousViewController = previousViewController
        self.referenceCurrentConstraint = referenceConstraint
        self.queue = queue
        self.delegate = delegate
    }

    private var length: CGFloat {
        parentViewController?.view.frame.width ?? .zero
    }

    private func progress(by offset: CGFloat) -> CGFloat {
        length > .zero ? (offset / length) : .zero
    }

    func start() {
        guard previousViewController.parent == nil else {
            fatalError()
        }

        self.referencePreviousConstraint = delegate?.attachViewController(
            previousViewController,
            at: .zero,
            offset: -0.4
        )
    }

    func move(offset: CGFloat) {
        guard offset >= .zero else {
            return
        }

        let length = length
        let progress = progress(by: offset)

        referenceCurrentConstraint?.constant = progress * length
        referencePreviousConstraint?.constant = ((progress * length) - length) * 0.4
    }

    func cancel() {
        let progress = progress(by: referenceCurrentConstraint?.constant ?? .zero)

        if progress == .zero {
            dropPrevious()
            return
        }

        queue?.append(.sync {
            await UIViewPropertyAnimator.perform(
                withDuration: 0.15 + (progress * 0.15),
                delay: .zero,
                options: .transitionFlipFromRight,
                animations: {
                    self.referenceCurrentConstraint?.constant = .zero
                    self.parentViewController?.view.layoutIfNeeded()
                }
            )

            self.dropPrevious()
        })
    }

    func commit() {
        guard let referencePreviousConstraint = referencePreviousConstraint else {
            return
        }

        let length = length
        let progress = progress(by: referenceCurrentConstraint?.constant ?? .zero)

        guard progress >= 0.5 else {
            cancel()
            return
        }

        if progress == 1 {
            delegate?.didPopViewController(
                currentViewController,
                previousViewController,
                referenceConstraint: referencePreviousConstraint
            )
            return
        }

        queue?.append(.sync {
            await UIViewPropertyAnimator.perform(
                withDuration: (1 + ((progress - 0.5) / 0.5)) * 0.15,
                delay: .zero,
                options: .transitionFlipFromRight,
                animations: {
                    self.referenceCurrentConstraint?.constant = length
                    self.referencePreviousConstraint?.constant = .zero
                    self.parentViewController?.view.layoutIfNeeded()
                }
            )

            self.delegate?.didPopViewController(
                self.currentViewController,
                self.previousViewController,
                referenceConstraint: referencePreviousConstraint
            )
        })
    }
}

extension StackGestureCoordinator {

    func dropPrevious() {
        previousViewController.willMove(toParent: nil)
        previousViewController.view.removeFromSuperview()
        previousViewController.removeFromParent()
    }
}

extension StackGestureCoordinator {

    func isRunning(for viewController: UIViewController) -> Bool {
        currentViewController === viewController
    }
}
