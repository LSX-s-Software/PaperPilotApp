//
//  PaperReader.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/25.
//

import SwiftUI
import PDFKit

private enum SidebarContent: String, Identifiable, CaseIterable {
    case info = "Info"
    case note = "Note"
    
    var id: Self {
        self
    }
}

private enum EditableContent {
    case none
    case title
    case author
}

struct PaperReader: View {
    @Bindable var paper: Paper
    
    @AppStorage(AppStorageKey.Reader.sidebarContent.rawValue)
    private var sidebarContent = SidebarContent.info
    
    @State private var loading = true
    @State private var errorDescription: String?
    @State private var pdf: PDFDocument?
    @State private var isImporting = false
    @State private var isShowingEditButton = EditableContent.none
    @State private var editing = EditableContent.none
    @State private var newAuthor = ""
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                HSplitView {
                    Group {
                        if loading {
                            ProgressView()
                        } else if let pdf = pdf {
                            PDFReader(paper: paper, pdf: pdf)
                        } else {
                            VStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.red)
                                    .font(.title)
                                if paper.file == nil {
                                    Text("This paper has no PDF file attached.")
                                        .foregroundStyle(.secondary)
                                    Button("Add PDF File") {
                                        isImporting.toggle()
                                    }
                                    .fileImporter(
                                        isPresented: $isImporting,
                                        allowedContentTypes: [.pdf],
                                        onCompletion: handleImportFile
                                    )
                                } else {
                                    Text(errorDescription ?? String(localized: "Unknown error"))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            Group {
                                Text(paper.title)
                                    .font(.title)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .overlay(alignment: .trailing) {
                                        if isShowingEditButton == .title {
                                            Button {
                                                editing = .title
                                            } label: {
                                                Image(systemName: "pencil")
                                            }
                                        }
                                    }
                                    .onHover { hover in
                                        isShowingEditButton = hover ? .title : .none
                                    }
                                    .popover(
                                        isPresented: Binding { editing == .title } set: { _ in editing = .none },
                                        arrowEdge: .bottom
                                    ) {
                                        TextField("Enter title", text: $paper.title)
                                            .padding()
                                            .onSubmit {
                                                editing = .none
                                            }
                                    }
                                Text(paper.formattedAuthors)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .overlay(alignment: .trailing) {
                                        if isShowingEditButton == .author {
                                            Button {
                                                editing = .author
                                            } label: {
                                                Image(systemName: "pencil")
                                            }
                                        }
                                    }
                                    .onHover { hover in
                                        isShowingEditButton = hover ? .author : .none
                                    }
                                    .popover(
                                        isPresented: Binding { editing == .author } set: { _ in editing = .none },
                                        arrowEdge: .bottom
                                    ) {
                                        List {
                                            ForEach(paper.authors, id: \.self) { author in
                                                Text(author)
                                            }
                                            .onDelete { paper.authors.remove(atOffsets: $0) }
                                            Section("Add author") {
                                                TextField("New author", text: $newAuthor)
                                                Button("Add") {
                                                    paper.authors.append(newAuthor)
                                                    newAuthor = ""
                                                }
                                                .keyboardShortcut(.defaultAction)
                                            }
                                        }
                                    }
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
        loading = true
        Task {
            defer { loading = false }
            guard let bookmark = paper.file else { return }
            var bookmarkStale = false
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
    
    func handleImportFile(result: Result<URL, Error>) {
        loading = true
        Task {
            do {
                switch result {
                case .success(let url):
                    if paper.url == nil {
                        paper.url = url.path
                    }
                    let didStartAccessing = url.startAccessingSecurityScopedResource()
                    defer { url.stopAccessingSecurityScopedResource() }
                    if didStartAccessing {
                        paper.file = try url.bookmarkData(options: .withSecurityScope)
                        pdf = PDFDocument(url: url)
                        errorDescription = nil
                    } else {
                        errorDescription = "Failed to access the file"
                    }
                case .failure(let error):
                    throw error
                }
            } catch {
                errorDescription = error.localizedDescription
            }
            loading = false
        }
    }
}

#Preview {
    PaperReader(paper: ModelData.paper1)
#if os(macOS)
        .frame(width: 900, height: 600)
#endif
}
