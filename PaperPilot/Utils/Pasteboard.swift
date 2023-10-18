//
//  Pasteboard.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/18.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

func setPasteboard(_ string: String) {
#if os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(string, forType: .string)
#else
    UIPasteboard.general.string = string
#endif
}
