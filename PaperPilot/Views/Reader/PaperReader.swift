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
        GeometryReader { proxy in
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
                        PaperInfo(paper: paper)
                    } else {
                        TextEditor(text: $note)
                    }
                }
                .frame(minWidth: 100, idealWidth: proxy.size.width / 4, maxWidth: proxy.size.width / 2)
            }
        }
    }
}

#Preview {
    PaperReader(paper: ModelData.paper1)
}
