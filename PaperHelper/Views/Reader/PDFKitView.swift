//
//  PDFKitView.swift
//  PaperHelper
//
//  Created by 林思行 on 2023/9/25.
//

import SwiftUI
import PDFKit

#if os(macOS)
struct PDFKitView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: NSViewRepresentableContext<PDFKitView>) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: self.url)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateNSView(_ uiView: PDFView, context: NSViewRepresentableContext<PDFKitView>) { }
}
#else
struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: UIViewRepresentableContext<PDFKitView>) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: self.url)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: UIViewRepresentableContext<PDFKitView>) { }
}
#endif
