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

#if os(macOS)
extension NSImage {
    func pngData(imageInterpolation: NSImageInterpolation = .high) -> Data? {
        let size = CGSize(width: self.size.width, height: self.size.height)
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: [],
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return nil
        }

        bitmap.size = size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.current?.imageInterpolation = imageInterpolation
        draw(
            in: NSRect(origin: .zero, size: size),
            from: .zero,
            operation: .copy,
            fraction: 1.0
        )
        NSGraphicsContext.restoreGraphicsState()

        return bitmap.representation(using: .png, properties: [:])
    }
}
#endif
