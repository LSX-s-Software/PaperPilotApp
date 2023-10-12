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
    let level: Int
    let outline: PDFOutline
    var children: [PDFOutlineItem]?
}

private func processOutline(root: PDFOutline, level: Int = 0) -> PDFOutlineItem {
    var outlineItem = PDFOutlineItem(level: level, outline: root)
    if root.numberOfChildren == 0 {
        return outlineItem
    }
    outlineItem.children = []
    for index in 0..<root.numberOfChildren {
        let child = root.child(at: index)!
        outlineItem.children!.append(processOutline(root: child, level: level + 1))
    }
    return outlineItem
}

struct PDFOutlineView: View {
    let root: PDFOutline
    let onSelectPage: ((PDFPage) -> Void)?
    
    @State private var outline: PDFOutlineItem
    @State private var selection: PDFOutlineItem?
    
    init(root: PDFOutline, onSelectPage: ((PDFPage) -> Void)? = nil) {
        self.root = root
        self._outline = State(initialValue: processOutline(root: root))
        self.onSelectPage = onSelectPage
    }
    
    var body: some View {
        List(outline.children ?? [], children: \.children, selection: $selection) { item in
            Button {
                guard let page = item.outline.destination?.page else { return }
                onSelectPage?(page)
            } label: {
                HStack {
                    Text(item.outline.label ?? "")
                    Spacer()
                    if let label = item.outline.destination?.page?.label {
                        Text(label)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.link)
        }
        .listStyle(.sidebar)
    }
}

#Preview {
    PDFOutlineView(root: PDFDocument(url: Bundle.main.url(forResource: "sample", withExtension: "pdf")!)!.outlineRoot!)
        .frame(width: 150, height: 500)
}
