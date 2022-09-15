//
//  StackInstruction.swift
//
//
//  Created by onnerb on 14/09/22.
//

import UIKit

struct StackInstruction {

    let type: StackInstructionType
    let viewController: UIViewController?
    let animated: Bool

    private init(
        type: StackInstructionType,
        viewController: UIViewController?,
        animated: Bool
    ) {
        self.type = type
        self.viewController = viewController
        self.animated = animated
    }
}

extension StackInstruction {

    static func push(_ viewController: UIViewController, animated: Bool) -> Self {
        .init(
            type: .push,
            viewController: viewController,
            animated: animated
        )
    }

    static func pop(_ viewController: UIViewController, animated: Bool) -> Self {
        .init(
            type: .pop,
            viewController: viewController,
            animated: animated
        )
    }

    static func erase(animated: Bool) -> Self {
        .init(
            type: .erase,
            viewController: nil,
            animated: animated
        )
    }

    static func insert(_ viewController: UIViewController, at index: Int) -> Self {
        .init(
            type: .insert(at: index),
            viewController: viewController,
            animated: false
        )
    }

    static func sync(_ operation: @escaping () async -> Void) -> Self {
        .init(
            type: .sync(operation),
            viewController: nil,
            animated: false
        )
    }
}
