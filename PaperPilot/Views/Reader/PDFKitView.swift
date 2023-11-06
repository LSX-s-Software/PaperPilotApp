//
//  PDFKitView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/25.
//

import SwiftUI
import PDFKit
import PencilKit
import OSLog
import Throttler

private let logger = LoggerFactory.make(category: "PDFKitView")

#if os(macOS)
struct PDFKitView: NSViewRepresentable {
    let pdf: PDFDocument
    @Binding var pdfView: PDFView
    @Binding var markupMode: Bool

    func makeNSView(context: NSViewRepresentableContext<PDFKitView>) -> PDFView {
        pdfView.autoScales = true
        pdfView.document = pdf
        return pdfView
    }
    
    func updateNSView(_ view: PDFView, context: NSViewRepresentableContext<PDFKitView>) {
        view.isInMarkupMode = markupMode
    }
}
#else
struct PDFKitView: UIViewRepresentable {
    let pdf: PDFDocument
    @Binding var pdfView: PDFView
    @Binding var markupMode: Bool

    func makeUIView(context: UIViewRepresentableContext<PDFKitView>) -> PDFView {
        pdfView.pageOverlayViewProvider = context.coordinator
        pdfView.autoScales = true
        pdf.delegate = context.coordinator
        pdfView.document = pdf
        return pdfView
    }
    
    func updateUIView(_ view: PDFView, context: UIViewRepresentableContext<PDFKitView>) {
        if markupMode != view.isInMarkupMode, let currentPage = view.currentPage {
            view.isInMarkupMode = markupMode
            DispatchQueue.main.async {
                if markupMode {
                    context.coordinator.pageToViewMapping[currentPage]?.becomeFirstResponder()
                } else {
                    view.currentFirstResponder?.resignFirstResponder()
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, PDFDocumentDelegate, PDFPageOverlayViewProvider, PKCanvasViewDelegate {
        var toolPicker = PKToolPicker()
        var pageToViewMapping = [PDFPage: PKCanvasView]()

        // MARK: - PDFDocument Delegate
        func classForPage() -> AnyClass {
            return DrawedPDFPage.self
        }

        func `class`(forAnnotationType annotationType: String) -> AnyClass {
            if annotationType == PKPDFAnnotation.subtypeString {
                return PKPDFAnnotation.self
            } else {
                return PDFAnnotation.self
            }
        }

        // MARK: - PDFPage Overlay View Provider
        func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> UIView? {
            var resultView: PKCanvasView?

            if let overlayView = pageToViewMapping[page] {
                resultView = overlayView
            } else {
                let canvasView = PKCanvasView(frame: .zero)
                canvasView.backgroundColor = UIColor.clear
                canvasView.delegate = self
                toolPicker.addObserver(canvasView)
                toolPicker.setVisible(true, forFirstResponder: canvasView)
                pageToViewMapping[page] = canvasView
                resultView = canvasView
            }

            // If we have stored a drawing on the page, set it on the canvas
            if let page = page as? DrawedPDFPage {
                if let drawing = page.drawing {
                    resultView?.drawing = drawing
                } else if let stampAnnotation = page.annotations.first(where: { $0.type == PKPDFAnnotation.subtypeString }),
                          let pkAnnotation = stampAnnotation as? PKPDFAnnotation,
                          let drawingData = pkAnnotation.value(forAnnotationKey: PKPDFAnnotation.annotationKey) as? Data {
                    do {
                        if let drawing = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(drawingData) as? PKDrawing {
                            resultView?.drawing = drawing
                        } else {
                            logger.warning("Drawing data cannot convert to PKDrawing")
                        }
                    } catch {
                        logger.warning("Failed to decode: \(error)")
                    }
                }
            }
            return resultView
        }

        func pdfView(_ pdfView: PDFView, willEndDisplayingOverlayView overlayView: UIView, for page: PDFPage) {
            if let overlayView = overlayView as? PKCanvasView, let page = page as? DrawedPDFPage {
                page.drawing = overlayView.drawing
            }
            pageToViewMapping.removeValue(forKey: page)
        }

        // MARK: - PKCanvasView Delegate
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            debounce {
                guard let page = self.pageToViewMapping.first(where: { $0.value == canvasView })?.key as? DrawedPDFPage else {
                    return
                }
                page.drawing = canvasView.drawing
            }
        }
    }
}

class DrawedPDFPage: PDFPage {
    var drawing: PKDrawing?
}

extension PDFAnnotationSubtype {
    static let pencilKitDrawing = PDFAnnotationSubtype(rawValue: "/PencilKitDrawing")
}

class PKPDFAnnotation: PDFAnnotation {
    static let annotationKey = PDFAnnotationKey(rawValue: "drawingData")
    static let subtypeString = String(PDFAnnotationSubtype.pencilKitDrawing.rawValue.dropFirst())
}

extension PDFDocument {
    func writeWithMarkup(to url: URL, withOptions options: [PDFDocumentWriteOption: Any]? = nil) -> Bool {
        for i in 0..<pageCount {
            if let page = page(at: i) as? DrawedPDFPage, let drawing = page.drawing {
                // 获取已有的标注数据
                let existingMarkupAnnotation = page.annotations.filter({ $0.type == PKPDFAnnotation.subtypeString })

                let markupAnnotation = PDFAnnotation(bounds: drawing.bounds, forType: .pencilKitDrawing, withProperties: nil)
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
