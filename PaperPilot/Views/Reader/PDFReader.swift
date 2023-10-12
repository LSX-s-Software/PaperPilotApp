//
//  PDFReader.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/11.
//

import SwiftUI
import PDFKit

struct PDFReader: View {
    let pdf: PDFDocument
    
    enum TOCContentType: String, Identifiable, CaseIterable {
        case none = "Hide TOC"
        case outline = "Outline"
        case thumbnail = "Thumbnail"
        
        var id: Self { self }
    }
    @State private var tocContent: TOCContentType = .outline
    
    @State private var pdfView = PDFView()
    
    var body: some View {
        // MARK: - 阅读器
        HStack {
            switch tocContent {
            case .none:
                EmptyView()
            case .outline:
                Group {
                    if let root = pdf.outlineRoot {
                        PDFOutlineView(root: root) { page in
                            pdfView.go(to: page)
                        }
                    } else {
                        Text("No Outline")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 175)
            case .thumbnail:
                PDFKitThumbnailView(pdfView: $pdfView, thumbnailWidth: 100)
                    .frame(width: 150)
            }
            
            PDFKitView(pdf: pdf, pdfView: $pdfView)
        }
        .animation(.easeInOut, value: tocContent)
        // MARK: - 工具栏
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Menu {
                    Picker("Table of Contents", selection: $tocContent) {
                        ForEach(TOCContentType.allCases) { type in
                            Text(LocalizedStringKey(type.rawValue))
                                .tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    Label("Table of Contents", systemImage: "sidebar.squares.left")
                }
            }
        }
    }
}

#Preview {
    PDFReader(pdf: PDFDocument(url: Bundle.main.url(forResource: "sample", withExtension: "pdf")!)!)
}
