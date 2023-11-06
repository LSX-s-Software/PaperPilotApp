//
//  PDFKitView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/25.
//

import SwiftUI
import PDFKit
import PencilKit

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
            if annotationType == PDFAnnotationSubtype.stamp.rawValue {
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
                toolPicker.addObserver(canvasView)
                toolPicker.setVisible(true, forFirstResponder: canvasView)
                pageToViewMapping[page] = canvasView
                resultView = canvasView
            }

            // If we have stored a drawing on the page, set it on the canvas
            if let page = page as? DrawedPDFPage, let drawing = page.drawing {
                resultView?.drawing = drawing
            }
            return resultView
        }

        func pdfView(_ pdfView: PDFView, willEndDisplayingOverlayView overlayView: UIView, for page: PDFPage) {
            if let overlayView = overlayView as? PKCanvasView, let page = page as? DrawedPDFPage {
                page.drawing = overlayView.drawing
            }
            pageToViewMapping.removeValue(forKey: page)
        }
    }
}

class DrawedPDFPage: PDFPage {
    var drawing: PKDrawing?
}

extension UIView {
    var currentFirstResponder: UIResponder? {
        if self.isFirstResponder {
            return self
        }

        for view in self.subviews {
            if let responder = view.currentFirstResponder {
                return responder
            }
        }

        return nil
     }
}
#endif
