//
//  PlatformSupport.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/11/1.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct PlatformSize {
    var width: CGFloat
    var height: CGFloat

#if os(macOS)
    var size: NSSize {
        NSSize(width: width, height: height)
    }
#else
    var size: CGSize {
        CGSize(width: width, height: height)
    }
#endif
}

struct PlatformColor: Codable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat

#if os(macOS)
    var color: NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
#else
    var color: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
#endif
}

extension PlatformColor {
    #if os(macOS)
    init(_ nsColor: NSColor) {
        red = nsColor.redComponent
        green = nsColor.greenComponent
        blue = nsColor.blueComponent
        alpha = nsColor.alphaComponent
    }
    #else
    init(_ uiColor: UIColor) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    #endif
}
