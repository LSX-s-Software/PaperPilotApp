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

private func processOutline(root: PDFOutline) -> PDFOutlineItem {
    var outlineItem = PDFOutlineItem(outline: root)
    if root.numberOfChildren == 0 {
        return outlineItem
    }
    outlineItem.children = []
    for index in 0..<root.numberOfChildren {
        let child = root.child(at: index)!
        outlineItem.children!.append(processOutline(root: child))
    }
    return outlineItem
}

struct PDFOutlineView: View {
    let root: PDFOutline
    
    @State private var outline: PDFOutlineItem
    @Binding private var selection: PDFPage
    
    init(root: PDFOutline, selection: Binding<PDFPage>) {
        self.root = root
        self._outline = State(initialValue: processOutline(root: root))
        self._selection = selection
    }
    
    var body: some View {
        List(outline.children ?? [], children: \.children, selection: $selection) { item in
            HStack {
                Text(item.outline.label ?? "")
                Spacer()
                if let label = item.outline.destination?.page?.label {
                    Text(label)
                        .foregroundStyle(.secondary)
                }
            }
            .tag(item.outline.destination?.page ?? PDFPage())
        }
        .listStyle(.sidebar)
    }
}

#Preview {
    PDFOutlineView(root: PDFDocument(url: Bundle.main.url(forResource: "sample", withExtension: "pdf")!)!.outlineRoot!,
                   selection: .constant(PDFPage()))
        .frame(width: 150, height: 500)
}
