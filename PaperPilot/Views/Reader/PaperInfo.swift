//
//  PaperInfo.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/27.
//

import SwiftUI
import SwiftUIFlow

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
                HStack {
                    Text("DOI")
                    Spacer()
                    Text(paper.doi ?? "未知")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("出版方")
                    Spacer()
                    Text(paper.publication ?? "未知")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("出版时间")
                    Spacer()
                    Text(paper.formattedYear)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("卷号")
                    Spacer()
                    Text(paper.volume ?? "未知")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("期号")
                    Spacer()
                    Text(paper.issue ?? "未知")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("页码")
                    Spacer()
                    Text(paper.pages ?? "未知")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("URL")
                    Spacer()
                    Link(paper.url ?? "", destination: URL(string: paper.url ?? "")!)
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
