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
            Text(LocalizedStringKey(title))
            Spacer()
            EditableText(content, prompt: "Enter \(title)", onEditEnd: onEditEnd)
        }
    }
}

struct PaperInfo: View {
    @Bindable var paper: Paper
    
    var body: some View {
        List {
            Section("Tags") {
                VFlow(alignment: .leading, spacing: 4) {
                    ForEach(paper.tags, id: \.self) { tag in
                        TagView(text: tag) { newValue in
                            let index = paper.tags.firstIndex(of: tag)!
                            paper.tags[index] = newValue
                        } onDelete: {
                            paper.tags.removeAll { $0 == tag }
                        }
                    }
                    AddTagView { newTag in
                        paper.tags.append(newTag)
                    }
                }
            }
            .listRowSeparator(.hidden)
            
            Section("Info") {
                InfoRow(title: "DOI", content: paper.doi) { newValue in
                    paper.doi = newValue
                }
                InfoRow(title: "Publication", content: paper.publication) { newValue in
                    paper.publication = newValue
                }
                InfoRow(title: "Publication Year", content: paper.publicationYear) { newValue in
                    paper.publicationYear = newValue
                }
                InfoRow(title: "Volume", content: paper.volume) { newValue in
                    paper.volume = newValue
                }
                InfoRow(title: "Issue", content: paper.issue) { newValue in
                    paper.issue = newValue
                }
                InfoRow(title: "Pages", content: paper.pages) { newValue in
                    paper.pages = newValue
                }
                InfoRow(title: "URL", content: paper.url) { newValue in
                    paper.url = newValue
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
                    ForEach(paper.keywords, id: \.self) { keyword in
                        TagView(text: keyword) { newValue in
                            let index = paper.keywords.firstIndex(of: keyword)!
                            paper.keywords[index] = newValue
                        } onDelete: {
                            paper.keywords.removeAll { $0 == keyword }
                        }
                    }
                    AddTagView { newTag in
                        paper.keywords.append(newTag)
                    }
                }
            }
            .listRowSeparator(.hidden)
            
            Section("Abstract") {
                TextEditor(text: Binding { paper.abstract ?? "" } set: { paper.abstract = $0 })
                    .font(.body)
                    .disabled(true)
                    .frame(minHeight: 150)
            }
        }
#if !os(macOS)
        .listStyle(.insetGrouped)
#endif
    }
}

#Preview {
    PaperInfo(paper: ModelData.paper1)
        .modelContainer(previewContainer)
}
