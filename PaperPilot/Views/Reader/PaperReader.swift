//
//  PaperReader.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/25.
//

import SwiftUI

struct PaperReader: View {
    @Bindable var paper: Paper
    
    enum SidebarContent: String, Identifiable, CaseIterable {
        case info = "信息"
        case note = "笔记"
        
        var id: Self {
            self
        }
    }
    @AppStorage(AppStorageKey.Reader.sidebarContent.rawValue)
    var sidebarContent = SidebarContent.info
    
    @State var note = ""
    
    var body: some View {
        GeometryReader { proxy in
            HSplitView {
                Group {
                    if let url = paper.file {
                        PDFKitView(url: url)
                            .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.red)
                                .font(.title)
                            Text("No Document")
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
                        
                        Picker("Sidebar Content", selection: $sidebarContent) {
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
                .frame(minWidth: 100, idealWidth: proxy.size.width / 4, maxWidth: proxy.size.width / 3)
            }
        }
    }
}

#Preview {
    PaperReader(paper: ModelData.paper1)
#if os(macOS)
        .frame(width: 900, height: 600)
#endif
}
