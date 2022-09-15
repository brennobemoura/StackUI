//
//  UIViewController+Environment.swift
//
//
//  Created by onnerb on 14/09/22.
//

import UIKit
import AssociationKit

extension UIViewController {

    var environment: AssociationEnvironment {
        .environment(self)
    }
}
