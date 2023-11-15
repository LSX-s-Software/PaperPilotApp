//
//  ShareViewController.swift
//  PaperPilotShareExtension
//
//  Created by 林思行 on 2023/11/14.
//

import SwiftUI

#if canImport(UIKit)
import UIKit

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
#elseif canImport(AppKit)
import Cocoa

class ShareViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            close()
            return
        }
        
        let rootView = ShareExtensionView(itemProviders: attachments, close: close)
        let contentView = NSHostingController(rootView: rootView)
        self.addChild(contentView)
        self.view.addSubview(contentView.view)

        // Set up constraints
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        contentView.view.bottomAnchor.constraint (equalTo: self.view.bottomAnchor).isActive = true
        contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        contentView.view.rightAnchor.constraint (equalTo: self.view.rightAnchor).isActive = true
    }

    func close() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
#endif
