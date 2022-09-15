//
//  File.swift
//
//
//  Created by onnerb on 14/09/22.
//

import UIKit

@MainActor
protocol StackGestureDelegate: AnyObject {

    func attachViewController(
        _ viewController: UIViewController,
        at index: Int,
        offset: CGFloat
    ) -> NSLayoutConstraint?

    func didPopViewController(
        _ viewController: UIViewController,
        _ topViewController: UIViewController,
        referenceConstraint: NSLayoutConstraint
    )
}
