//
//  File.swift
//
//
//  Created by onnerb on 14/09/22.
//

import UIKit

@MainActor
protocol StackOutputDelegate: AnyObject {

    func numberOfViewControllers() -> Int

    func previousViewController() -> UIViewController?

    func outputWillPushViewController(_ viewController: UIViewController)

    func outputDidPushViewController(_ viewController: UIViewController)

    func outputDidPopViewController(_ viewController: UIViewController)

    func outputDidInsertViewController(
        _ viewController: UIViewController,
        at index: Int
    )

    func outputDidRemoveViewControllers()
}
