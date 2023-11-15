//
//  UIKitExtensions.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/11/6.
//

#if os(iOS) || os(visionOS)
import UIKit

extension UIView {
    var currentFirstResponder: UIResponder? {
        if self.isFirstResponder {
            return self
        }

        for view in self.subviews {
            if let responder = view.currentFirstResponder {
                return responder
            }
        }

        return nil
     }
}
#endif
