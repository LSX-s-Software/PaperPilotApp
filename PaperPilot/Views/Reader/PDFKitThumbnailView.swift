//
//  PDFKitThumbnailView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/11.
//

import SwiftUI
import PDFKit

#if os(macOS)
struct PDFKitThumbnailView: NSViewRepresentable {
    @Binding var pdfView: PDFView
    var thumbnailWidth = 100
    
    func makeNSView(context: NSViewRepresentableContext<PDFKitThumbnailView>) -> PDFThumbnailView {
        let thumbnailView = PDFThumbnailView()
        thumbnailView.pdfView = pdfView
        thumbnailView.thumbnailSize = CGSize(width: Double(thumbnailWidth), height: Double(thumbnailWidth) / 21.0 * 29.7)
        return thumbnailView
    }
    
    func updateNSView(_ uiView: PDFThumbnailView, context: NSViewRepresentableContext<PDFKitThumbnailView>) { }
}
#else
struct PDFKitThumbnailView: UIViewRepresentable {
    @Binding var pdfView: PDFView
    var thumbnailWidth = 100
    
    func makeUIView(context: UIViewRepresentableContext<PDFKitThumbnailView>) -> PDFThumbnailView {
        let thumbnailView = PDFThumbnailView()
        thumbnailView.pdfView = pdfView
        thumbnailView.thumbnailSize = CGSize(width: Double(thumbnailWidth), height: Double(thumbnailWidth) / 21.0 * 29.7)
        return thumbnailView
    }
    
    func updateUIView(_ uiView: PDFThumbnailView, context: UIViewRepresentableContext<PDFKitThumbnailView>) { }
}
#endif
