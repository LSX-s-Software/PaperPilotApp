//
//  ShareViewController.swift
//  PaperPilotShareExtension
//
//  Created by 林思行 on 2023/11/14.
//

import SwiftUI

#if canImport(AppKit)
import Cocoa
class ShareViewController: NSViewController { }
#else
import UIKit
class ShareViewController: UIViewController { }
#endif

extension ShareViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            close()
            return
        }

        let rootView = ShareExtensionView(itemProviders: attachments, close: close)
#if canImport(AppKit)
        let contentView = NSHostingController(rootView: rootView)
#else
        let contentView = UIHostingController(rootView: rootView)
#endif
        self.addChild(contentView)
        self.view.addSubview(contentView.view)

        // Set up constraints
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        contentView.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        contentView.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
    }

    func close() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
