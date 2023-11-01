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
