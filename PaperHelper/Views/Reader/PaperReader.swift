//
//  PaperReader.swift
//  PaperHelper
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
                        Text(paper.name)
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
                        
                        Section("基本信息") {
                            HStack {
                                Text("DOI")
                                Spacer()
                                Text(paper.doi ?? "未知")
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Text("来源")
                                Spacer()
                                Text(paper.source ?? "未知")
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Text("出版时间")
                                Spacer()
                                Text(paper.formattedYear)
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
                            
                        }
                        
                        Section("摘要") {
                            
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
    PaperReader(paper: ModelData.paper2)
}
