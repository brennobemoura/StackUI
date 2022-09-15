//
//  StackController.swift
//  
//
//  Created by onnerb on 14/09/22.
//

import UIKit

@MainActor
open class StackController: UIViewController {

    private var _viewControllers: [UIViewController] = []

    private let queue = StackQueue()
    private let output = StackOutput()
    private var gestureCoordinator: StackGestureCoordinator?

    private lazy var gestureManager = DragManager(self)

    @MainActor
    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibName:bundle:) has not been implemented")
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func pushViewController(_ viewController: UIViewController, animated: Bool) {
        guard !viewControllers.contains(viewController) else {
            fatalError()
        }

        queue.append(.push(viewController, animated: animated))
    }

    open func popViewController(animated: Bool) {
        dismissGesture()

        if let lastViewController = viewControllers.last {
            queue.append(.pop(lastViewController, animated: animated))
        }
    }

    open func popToViewController(_ viewController: UIViewController, animated: Bool) {
        dismissGesture()

        let viewControllers = viewControllers

        guard let index = viewControllers.firstIndex(of: viewController) else {
            fatalError()
        }

        if index == viewControllers.endIndex - 1 {
            return
        }

        for viewController in viewControllers[index + 1 ..< viewControllers.endIndex - 1] {
            queue.append(.pop(viewController, animated: false))
        }

        popViewController(animated: animated)
    }

    open func popToRootViewController(animated: Bool) {
        dismissGesture()

        let viewControllers = viewControllers

        let startIndex = viewControllers.startIndex + 1
        let endIndex = viewControllers.endIndex - 1

        for viewController in viewControllers[startIndex ..< endIndex] {
            queue.append(.pop(viewController, animated: false))
        }

        popViewController(animated: animated)
    }

    open func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        dismissGesture()

        let currentViewControllers = self.viewControllers

        guard let lastViewController = viewControllers.last else {
            queue.append(.erase(animated: animated))
            return
        }

        if currentViewControllers.contains(lastViewController) {
            if currentViewControllers.last != lastViewController {
                popToViewController(lastViewController, animated: animated)
            }
        } else {
            pushViewController(lastViewController, animated: animated)
        }

        for viewController in self.viewControllers.reversed() where viewController != lastViewController {
            queue.append(.pop(viewController, animated: false))
        }

        for (index, viewController) in viewControllers.dropLast().enumerated() {
            queue.append(.insert(viewController, at: index))
        }
    }
}

extension StackController {

    public override func viewDidLoad() {
        super.viewDidLoad()
        output.connect(queue, to: self)
        output.delegate = self

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureDidChange))
        view.addGestureRecognizer(panGesture)
        panGesture.delegate = gestureManager
    }
}

extension StackController {

    public var viewControllers: [UIViewController] {
        queue.reduce(_viewControllers)
    }
}

extension StackController: StackOutputDelegate {

    func numberOfViewControllers() -> Int {
        _viewControllers.count
    }

    func previousViewController() -> UIViewController? {
        if _viewControllers.isEmpty {
            return nil
        }

        return _viewControllers.dropLast().last
    }

    func outputWillPushViewController(_ viewController: UIViewController) {
        _viewControllers.append(viewController)
    }

    func outputDidPushViewController(_ viewController: UIViewController) {
        viewController.stackController = self
    }

    func outputDidPopViewController(_ viewController: UIViewController) {
        _viewControllers.removeAll {
            $0 === viewController
        }
    }

    func outputDidInsertViewController(
        _ viewController: UIViewController,
        at index: Int
    ) {
        _viewControllers.insert(viewController, at: index)
    }

    func outputDidRemoveViewControllers() {
        _viewControllers.removeAll()
    }
}

extension StackController {

    public func performChanges(_ commit: () -> Void) {
        dismissGesture()

        guard !queue.isWorkingInProgress else {
            fatalError()
        }

        queue.lock()
        commit()
        queue.unlock()

        queue.performChanges {
            let index = $0.lastIndex(where: {
                if case .push = $0.type {
                    return true
                }

                return false
            })

            guard let index = index else {
                $0.forEach {
                    queue.append($0)
                }
                return
            }

            let reverse = $0[0..<index]
            let regular = $0[index..<$0.endIndex]

            for instruction in regular {
                queue.append(instruction)
            }

            let startIndex = viewControllers.endIndex - 1
            var increment = 0

            for instruction in reverse {
                if case .push = instruction.type, let viewController = instruction.viewController {
                    queue.append(.insert(viewController, at: startIndex + increment))
                    increment += 1
                } else {
                    queue.append(instruction)
                }
            }
        }
    }
}

extension StackController {

    func interactiveGestureDisabled(_ viewController: UIViewController) {
        guard !queue.isWorkingInProgress else {
            return
        }

        guard gestureCoordinator?.isRunning(for: viewController) ?? false else {
            return
        }

        dismissGesture()
    }

    func dismissGesture() {
        gestureCoordinator?.cancel()
        gestureCoordinator = nil
    }

    @objc
    func panGestureDidChange(_ panGesture: UIPanGestureRecognizer) {
        switch panGesture.state {
        case .began, .possible:
            gestureCoordinator = nil

            guard let previousViewController = _viewControllers.dropLast().last else {
                return
            }

            gestureCoordinator = output.makeGestureCoordinator(
                parent: self,
                previous: previousViewController
            )

            gestureCoordinator?.start()
        case .cancelled, .failed:
            dismissGesture()
        case .ended:
            gestureCoordinator?.commit()
            gestureCoordinator = nil
        case .changed:
            gestureCoordinator?.move(offset: panGesture.translation(in: view).x)
        @unknown default:
            dismissGesture()
        }
    }
}

extension StackController {

    class DragManager: NSObject, UIGestureRecognizerDelegate {
        private weak var stackController: StackController?

        init(_ stackController: StackController) {
            self.stackController = stackController
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard
                let stackController = stackController,
                stackController._viewControllers.count >= 2,
                let viewController = stackController._viewControllers.last
            else { return false }

            return viewController.isInteractivePopEnabled && (0...45).contains(gestureRecognizer.location(in: viewController.view).x)
        }
    }
}
