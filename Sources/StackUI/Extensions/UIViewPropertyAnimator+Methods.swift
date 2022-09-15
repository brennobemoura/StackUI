//
//  UIViewPropertyAnimator+Methods.swift
//
//
//  Created by onnerb on 14/09/22.
//

import UIKit

extension UIViewPropertyAnimator {

    @MainActor
    static func perform(
        withDuration duration: TimeInterval,
        delay: TimeInterval,
        options: UIView.AnimationOptions = [],
        animations: @escaping () -> Void
    ) async {
        await withUnsafeContinuation { continuation in
            _ = runningPropertyAnimator(
                withDuration: duration,
                delay: delay,
                options: options,
                animations: animations,
                completion: {
                    if $0 == .end {
                        continuation.resume()
                    }
                }
            )
        }
    }
}
