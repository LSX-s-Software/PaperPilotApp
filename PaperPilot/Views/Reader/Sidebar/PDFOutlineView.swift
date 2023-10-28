//
//  PDFOutlineView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/12.
//

import SwiftUI
import PDFKit

private struct PDFOutlineItem: Identifiable, Hashable {
    let id = UUID()
    let outline: PDFOutline
    var children: [PDFOutlineItem]?
}

struct PDFOutlineView: View {
    let root: PDFOutline?

    @EnvironmentObject private var pdfVM: PDFViewModel
    @State private var outline: PDFOutlineItem?

    var body: some View {
        List(selection: Binding { pdfVM.currentPage } set: {
            if let page = $0 {
                pdfVM.pdfView.go(to: page)
            }
        }) {
            if let outline = outline {
                OutlineGroup(outline.children ?? [], children: \.children) { item in
                    HStack {
                        Text(verbatim: item.outline.label ?? "")
                        Spacer()
                        if let label = item.outline.destination?.page?.label {
                            Text(label)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(item.outline.destination?.page ?? PDFPage())
                }
            }
        }
        .overlay {
            if root == nil {
                Text("No Outline")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            } else if outline == nil {
                ProgressView()
            }
        }
        .task(id: root) {
            outline = processOutline(root: root)
        }
    }

    private func processOutline(root: PDFOutline?) -> PDFOutlineItem? {
        guard let root = root else { return nil }
        var outlineItem = PDFOutlineItem(outline: root)
        if root.numberOfChildren == 0 {
            return outlineItem
        }
        outlineItem.children = []
        for index in 0..<root.numberOfChildren {
            if let child = root.child(at: index), let childOutline = processOutline(root: child) {
                outlineItem.children!.append(childOutline)
            }
        }
        return outlineItem
    }
}

#Preview {
    PDFOutlineView(root: PDFDocument(url: Bundle.main.url(forResource: "sample", withExtension: "pdf")!)!.outlineRoot)
        .environmentObject(PDFViewModel())
        .frame(width: 150, height: 500)
}
