//
//  PaperInfo.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/27.
//

import SwiftUI
import SwiftUIFlow

private struct InfoRow: View {
    let title: String
    let content: String?
    let onEditEnd: (String) -> Void
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            EditableText(content, prompt: "Enter Title" + title, onEditEnd: onEditEnd)
        }
    }
}

struct PaperInfo: View {
    var paper: Paper
    
    var body: some View {
        List {
            Section("Tags") {
                VFlow(alignment: .leading, spacing: 4) {
                    ForEach(paper.tags ?? [], id: \.self) { tag in
                        TagView(text: tag)
                    }
                    TagView(text: "Add", systemImage: "plus")
                }
            }
            .listRowSeparator(.hidden)
            
            Section("Info") {
                InfoRow(title: "DOI", content: paper.doi) { newValue in
                    
                }
                InfoRow(title: "Publication", content: paper.publication) { newValue in
                    
                }
                InfoRow(title: "Publication Date", content: paper.publicationYear) { newValue in
                    
                }
                InfoRow(title: "Volume", content: paper.volume) { newValue in
                    
                }
                InfoRow(title: "Issue", content: paper.issue) { newValue in
                    
                }
                InfoRow(title: "Pages", content: paper.pages) { newValue in
                    
                }
                InfoRow(title: "URL", content: paper.url) { newValue in
                    
                }
                HStack {
                    Text("Date Added")
                    Spacer()
                    Text(paper.formattedCreateTime)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Keywords") {
                VFlow(alignment: .leading, spacing: 4) {
                    ForEach(paper.keywords ?? [], id: \.self) { keyword in
                        TagView(text: keyword)
                    }
                    TagView(text: "Add", systemImage: "plus")
                }
            }
            .listRowSeparator(.hidden)
            
            Section("Abstract") {
                TextEditor(text: .constant(paper.abstract ?? "Not available."))
                    .font(.body)
                    .disabled(true)
            }
        }
#if !os(macOS)
        .listStyle(.insetGrouped)
#endif
    }
}

#Preview {
    PaperInfo(paper: ModelData.paper1)
}
