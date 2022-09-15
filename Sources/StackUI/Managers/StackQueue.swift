//
//  File.swift
//
//
//  Created by onnerb on 14/09/22.
//

import Foundation
import UIKit

@MainActor
class StackQueue {

    private var scheduled: [StackInstruction] = []
    private var isRunning: Bool = false
    private var isLocked: Bool = false

    weak var delegate: StackQueueDelegate?

    init() {}
}

extension StackQueue {

    var isWorkingInProgress: Bool {
        isRunning
    }
}

extension StackQueue {

    func lock() {
        isLocked = true
    }

    func unlock() {
        isLocked = false
    }
}

extension StackQueue {

    func perform() {
        guard !isLocked, let instruction = scheduled.first else {
            self.isRunning = false
            return
        }

        isRunning = true

        Task {
            switch instruction.type {
            case .push:
                if let viewController = instruction.viewController {
                    await delegate?.push(viewController, animated: instruction.animated)
                }
            case .erase:
                await delegate?.removeAll(animated: instruction.animated)
            case .insert(let index):
                if let viewController = instruction.viewController {
                    await delegate?.insert(viewController, at: index, animated: instruction.animated)
                }
            case .pop:
                if let viewController = instruction.viewController {
                    await delegate?.pop(viewController, animated: instruction.animated)
                }
            case .sync(let operation):
                await operation()
            }

            scheduled.removeFirst()
            perform()
        }
    }

    func append(_ instruction: StackInstruction) {
        scheduled.append(instruction)

        guard !isRunning else {
            return
        }

        perform()
    }
}

extension StackQueue {

    func reduce(_ viewControllers: [UIViewController]) -> [UIViewController] {
        var viewControllers = viewControllers

        for instruction in scheduled {
            switch instruction.type {
            case .erase:
                viewControllers = []
            case .pop:
                if let viewController = instruction.viewController {
                    viewControllers.removeAll {
                        $0 === viewController
                    }
                }
            case .push:
                if let viewController = instruction.viewController {
                    if !viewControllers.contains(viewController) {
                        viewControllers.append(viewController)
                    }
                }
            case .insert(let index):
                if let viewController = instruction.viewController {
                    if !viewControllers.contains(viewController) {
                        viewControllers.insert(viewController, at: index)
                    }
                }
            case .sync:
                break
            }
        }

        return viewControllers
    }
}

extension StackQueue {

    func performChanges(_ handler: ([StackInstruction]) -> Void) {
        lock()
        let scheduled = scheduled
        self.scheduled = []
        handler(scheduled)
        unlock()
        perform()
    }
}
