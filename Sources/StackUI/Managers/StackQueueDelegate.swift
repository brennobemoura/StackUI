//
//  StackQueueDelegate.swift
//
//
//  Created by onnerb on 14/09/22.
//

import UIKit

@MainActor
protocol StackQueueDelegate: AnyObject {

    func push(_ viewController: UIViewController, animated: Bool) async
    func pop(_ viewController: UIViewController, animated: Bool) async
    func insert(_ viewController: UIViewController, at index: Int, animated: Bool) async
    func removeAll(animated: Bool) async
}
