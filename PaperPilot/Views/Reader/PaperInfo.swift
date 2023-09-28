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
            EditableText(content, prompt: "请输入" + title, onEditEnd: onEditEnd)
        }
    }
}

struct PaperInfo: View {
    var paper: Paper
    
    var body: some View {
        List {
            Section("标签") {
                VFlow(alignment: .leading, spacing: 4) {
                    ForEach(paper.tags ?? [], id: \.self) { tag in
                        TagView(text: tag)
                    }
                    TagView(text: "添加", systemImage: "plus")
                }
            }
            .listRowSeparator(.hidden)
            
            Section("基本信息") {
                InfoRow(title: "DOI", content: paper.doi) { newValue in
                    
                }
                InfoRow(title: "出版方", content: paper.publication) { newValue in
                    
                }
                InfoRow(title: "出版时间", content: paper.publicationYear) { newValue in
                    
                }
                InfoRow(title: "卷号", content: paper.volume) { newValue in
                    
                }
                InfoRow(title: "期号", content: paper.issue) { newValue in
                    
                }
                InfoRow(title: "页码", content: paper.pages) { newValue in
                    
                }
                InfoRow(title: "URL", content: paper.url) { newValue in
                    
                }
                HStack {
                    Text("添加时间")
                    Spacer()
                    Text(paper.formattedCreateTime)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("关键词") {
                VFlow(alignment: .leading, spacing: 4) {
                    ForEach(paper.keywords ?? [], id: \.self) { keyword in
                        TagView(text: keyword)
                    }
                    TagView(text: "添加", systemImage: "plus")
                }
            }
            .listRowSeparator(.hidden)
            
            Section("摘要") {
                TextEditor(text: .constant(paper.abstract ?? "暂无摘要"))
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
