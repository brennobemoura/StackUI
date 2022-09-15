//
//  InteractivePopEnabledKey.swift
//  
//
//  Created by onnerb on 14/09/22.
//

import UIKit
import AssociationKit

struct InteractivePopEnabledKey: AssociationKey {
    static var defaultValue: Bool = true
}

extension AssociationValues {

    var isInteractivePopEnabled: Bool {
        get { self[InteractivePopEnabledKey.self] }
        set { self[InteractivePopEnabledKey.self] = newValue }
    }
}

extension UIViewController {

    public var isInteractivePopEnabled: Bool {
        get { environment.isInteractivePopEnabled }
        set {
            environment.isInteractivePopEnabled = newValue

            if !newValue {
                stackController?.interactiveGestureDisabled(self)
            }
        }
    }
}
