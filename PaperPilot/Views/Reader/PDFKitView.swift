//
//  PDFKitView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/25.
//

import SwiftUI
import PDFKit

#if os(macOS)
struct PDFKitView: NSViewRepresentable {
    let pdf: PDFDocument
    @Binding var pdfView: PDFView
    
    func makeNSView(context: NSViewRepresentableContext<PDFKitView>) -> PDFView {
        pdfView.document = pdf
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateNSView(_ uiView: PDFView, context: NSViewRepresentableContext<PDFKitView>) { }
}
#else
struct PDFKitView: UIViewRepresentable {
    let pdf: PDFDocument
    
    func makeUIView(context: UIViewRepresentableContext<PDFKitView>) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdf
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: UIViewRepresentableContext<PDFKitView>) { }
}
#endif
