//
//  PDF.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/11/6.
//

import Foundation
import PDFKit
import PencilKit

private let logger = LoggerFactory.make(category: "PDF")

class DrawedPDFPage: PDFPage {
    var drawing: PKDrawing?
}

extension PDFAnnotationSubtype {
    static let pencilKitDrawing = PDFAnnotationSubtype(rawValue: "/PencilKitDrawing")
}

class PKPDFAnnotation: PDFAnnotation {
    static let annotationKey = PDFAnnotationKey(rawValue: "drawingData")
    static let subtypeString = String(PDFAnnotationSubtype.pencilKitDrawing.rawValue.dropFirst())

#if os(macOS)
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        super.draw(with: box, in: context)

        NSGraphicsContext.current?.saveGraphicsState()
        context.saveGState()

        if let page = self.page as? DrawedPDFPage {
            // 如果没有已经解码的数据则从标注数据中解码
            if page.drawing == nil,
               let drawingData = self.value(forAnnotationKey: Self.annotationKey) as? Data {
                do {
                    if let drawing = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(drawingData) as? PKDrawing {
                        logger.trace("Successfully decoded drawing")
                        page.drawing = drawing
                    } else {
                        logger.warning("Failed to decode PKDrawing")
                    }
                } catch {
                    logger.warning("Error decoding data: \(error)")
                }
            }
            // 绘制标注图像
            if let drawing = page.drawing {
                let scaleFactor = NSApplication.shared.keyWindow?.screen?.backingScaleFactor ?? 2.0
                let image = drawing.image(from: drawing.bounds, scale: scaleFactor)
                if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    context.draw(cgImage, in: bounds)
                } else {
                    logger.warning("PKDrawing's image cannot convert to CGImage")
                }
            }
        }

        context.restoreGState()
        NSGraphicsContext.current?.restoreGraphicsState()
    }
#endif
}

#if !os(macOS)
extension PDFDocument {
    func writeWithMarkup(to url: URL, withOptions options: [PDFDocumentWriteOption: Any]? = nil) -> Bool {
        for i in 0..<pageCount {
            if let page = page(at: i) as? DrawedPDFPage, let drawing = page.drawing {
                // 获取已有的标注数据
                let existingMarkupAnnotation = page.annotations.filter({ $0.type == PKPDFAnnotation.subtypeString })

                let pageBounds = page.bounds(for: .cropBox)
                let annotationBounds = CGRect(x: drawing.bounds.minX,
                                              y: pageBounds.height - drawing.bounds.maxY,
                                              width: drawing.bounds.width,
                                              height: drawing.bounds.height)
                let markupAnnotation = PDFAnnotation(bounds: annotationBounds, forType: .pencilKitDrawing, withProperties: nil)
                if let codedData = try? NSKeyedArchiver.archivedData(withRootObject: drawing, requiringSecureCoding: true) {
                    markupAnnotation.setValue(codedData, forAnnotationKey: PKPDFAnnotation.annotationKey)
                    page.addAnnotation(markupAnnotation)
                    // 删除原有的标注数据
                    existingMarkupAnnotation.forEach({ page.removeAnnotation($0) })
                } else {
                    logger.warning("Failed to archive drawing")
                    return false
                }
            }
        }
        return self.write(to: url, withOptions: options)
    }
}
#endif
