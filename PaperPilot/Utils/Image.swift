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
typealias PlatformImage = NSImage

extension NSImage {
    /// Get the image's png data
    public func pngData(imageInterpolation: NSImageInterpolation = .high) -> Data? {
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

    /// Get the image's jpeg data
    public func jpegData() -> Data? {
        let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        let jpegData = bitmapRep.representation(using: .jpeg, properties: [:])!
        return jpegData
    }
}
#else
typealias PlatformImage = UIImage
#endif

extension PlatformImage {
    /// Resize the image to the given size.
    func resized(to targetSize: CGSize, aspectRatio: Bool) -> PlatformImage? {
        let newSize: CGSize
        if aspectRatio {
            let widthRatio  = targetSize.width / self.size.width
            let heightRatio = targetSize.height / self.size.height
            if widthRatio > heightRatio {
                newSize = CGSize(width: floor(self.size.width * widthRatio),
                                 height: floor(self.size.height * widthRatio))
            } else {
                newSize = CGSize(width: floor(self.size.width * heightRatio),
                                 height: floor(self.size.height * heightRatio))
            }
        } else {
            newSize = targetSize
        }
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

#if os(macOS)
        guard let representation = self.bestRepresentation(for: rect, context: nil, hints: nil) else {
            return nil
        }
        return NSImage(size: targetSize, flipped: false, drawingHandler: { (_) -> Bool in
            return representation.draw(in: rect)
        })
#else
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
#endif
    }

    func resized(notLargerThan maxSize: CGSize) -> PlatformImage? {
        let widthRatio  = maxSize.width / self.size.width
        let heightRatio = maxSize.height / self.size.height
        let ratio = min(widthRatio, heightRatio)
        return ratio >= 1 ? self : resized(to: CGSize(width: floor(self.size.width * ratio),
                                                      height: floor(self.size.height * ratio)),
                                           aspectRatio: true)
    }
}
