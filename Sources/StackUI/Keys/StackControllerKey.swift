//
//  StackControllerKey.swift
//
//
//  Created by onnerb on 14/09/22.
//

import UIKit
import AssociationKit

struct StackControllerKey: WeakAssociationKey {
    static var defaultValue: StackController?
}

extension AssociationValues {

    var stackController: StackController? {
        get { self[StackControllerKey.self] }
        set { self[StackControllerKey.self] = newValue }
    }
}

extension UIViewController {

    var stackController: StackController? {
        get { environment.stackController }
        set { environment.stackController = newValue }
    }
}
