//
//  PaperReader.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/25.
//

import SwiftUI
import PDFKit

struct PaperReader: View {
    @Bindable var paper: Paper
    
    enum SidebarContent: String, Identifiable, CaseIterable {
        case info = "Info"
        case note = "Note"
        
        var id: Self {
            self
        }
    }
    @AppStorage(AppStorageKey.Reader.sidebarContent.rawValue)
    var sidebarContent = SidebarContent.info
    
    @State private var loadingPDF = true
    @State private var errorDescription: String?
    @State private var pdf: PDFDocument?
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                HSplitView {
                    Group {
                        if loadingPDF {
                            ProgressView()
                        } else if let pdf = pdf {
                            PDFReader(paper: paper, pdf: pdf)
                        } else {
                            VStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.red)
                                    .font(.title)
                                Text(LocalizedStringKey(errorDescription ?? "Unknown error"))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
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
                                    Text(LocalizedStringKey(content.rawValue)).tag(content)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }
                        .padding([.horizontal, .top])
                        
                        if sidebarContent == .info {
                            PaperInfo(paper: paper)
                        } else {
                            TextEditor(text: $paper.note)
                        }
                    }
                    .frame(minWidth: 100, idealWidth: proxy.size.width / 4, maxWidth: proxy.size.width / 3)
                }
                .onAppear {
                    loadPDF()
                }
            }
        }
    }
    
    func loadPDF() {
        guard let bookmark = paper.file else {
            loadingPDF = false
            return
        }
        var bookmarkStale = false
        defer { loadingPDF = false }
        do {
            let resolvedUrl = try URL(resolvingBookmarkData: bookmark,
                                      options: .withSecurityScope,
                                      relativeTo: nil,
                                      bookmarkDataIsStale: &bookmarkStale)
            let didStartAccessing = resolvedUrl.startAccessingSecurityScopedResource()
            defer {
                resolvedUrl.stopAccessingSecurityScopedResource()
            }
            
            if bookmarkStale {
                paper.file = try resolvedUrl.bookmarkData(options: .withSecurityScope)
            }
            if !didStartAccessing {
                errorDescription = "Failed to access the file"
                return
            }
            
            pdf = PDFDocument(url: resolvedUrl)
        } catch {
            errorDescription = error.localizedDescription
        }
    }
}

#Preview {
    PaperReader(paper: ModelData.paper1)
#if os(macOS)
        .frame(width: 900, height: 600)
#endif
}
