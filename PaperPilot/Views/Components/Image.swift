//
//  Image.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/27.
//

import SwiftUI

extension Image {
#if os(macOS)
    init(image: NSImage) {
        self.init(nsImage: image)
    }
#else
    init(image: UIImage) {
        self.init(uiImage: image)
    }
#endif
}

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
