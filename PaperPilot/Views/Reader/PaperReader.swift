//
//  PaperReader.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/25.
//

import SwiftUI

struct PaperReader: View {
    let paper: Paper
    
    enum SidebarContent: String, Identifiable, CaseIterable {
        case info = "信息"
        case note = "笔记"
        
        var id: Self {
            self
        }
    }
    @AppStorage("reader.sidebarContent")
    var sidebarContent = SidebarContent.info
    
    @State var note = ""
    
    var body: some View {
        HSplitView {
            Group {
                if let url = paper.file {
                    PDFKitView(url: url)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.red)
                            .font(.title)
                        Text("PDF不存在")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Group {
                        Text(paper.title)
                            .font(.title)
                        Text(paper.formattedAuthors)
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.leading)
                    
                    Picker("边栏内容", selection: $sidebarContent) {
                        ForEach(SidebarContent.allCases) { content in
                            Text(content.rawValue).tag(content)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .padding([.horizontal, .top])
                
                if sidebarContent == .info {
                    List {
                        Section("标签") {
                            LazyHGrid(rows: [GridItem()], spacing: 4) {
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
                                Text(paper.url ?? "未知")
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Text("添加时间")
                                Spacer()
                                Text(paper.formattedCreateTime)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Section("关键词") {
                            LazyHGrid(rows: [GridItem()], spacing: 4) {
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
                } else {
                    TextEditor(text: $note)
                }
            }
        }
    }
}

#Preview {
    PaperReader(paper: ModelData.paper1)
}
