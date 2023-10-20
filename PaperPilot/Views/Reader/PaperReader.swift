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
    @AppStorage(AppStorageKey.Reader.isShowingInspector.rawValue)
    private var isShowingInspector = true

    @State private var loading = true
    @State private var errorDescription: String?
    @State private var pdf: PDFDocument?
    @State private var isImporting = false
    @State private var isShowingEditButton = EditableContent.none
    @State private var editing = EditableContent.none
    @State private var newAuthor = ""
    @StateObject private var downloadVM = DownloadViewModel()
    
    var body: some View {
        NavigationStack {
            // MARK: - 左侧内容
            HStack {
                Group {
                    if loading {
                        ProgressView()
                    } else if let pdf = pdf {
                        PDFReader(paper: paper, pdf: pdf)
                    } else {
                        VStack(spacing: 6) {
                            Image(
                                systemName: downloadVM.downloading ?
                                "arrow.down.circle.fill" : "exclamationmark.triangle.fill"
                            )
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.red)
                            .font(.title)
                            if paper.file == nil {
                                Text("This paper has no PDF file attached.")
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                                Button("Add PDF File") {
                                    isImporting.toggle()
                                }
                                .fileImporter(
                                    isPresented: $isImporting,
                                    allowedContentTypes: [.pdf],
                                    onCompletion: handleImportFile
                                )
                                .fileDialogMessage("Select a PDF file to import")
                                .fileDialogConfirmationLabel("Import")
                            } else if downloadVM.downloading {
                                Text("Downloading PDF...")
                                    .font(.title)
                                Group {
                                    if let progress = downloadVM.downloadProgress {
                                        ProgressView(value: progress.fractionCompleted)
                                    } else {
                                        ProgressView()
                                    }
                                }
                                .progressViewStyle(.linear)
                                .padding(.horizontal)
                                .frame(maxWidth: 350)
                            } else {
                                Text(errorDescription ?? String(localized: "Unknown error"))
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            // MARK: - 右侧内容
            .inspector(isPresented: $isShowingInspector) {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Group {
                            Text(paper.title)
                                .font(.title)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .overlay(alignment: .trailing) {
                                    if isShowingEditButton == .title {
                                        Button("Edit", systemImage: "pencil") {
                                            editing = .title
                                        }
                                        .labelStyle(.iconOnly)
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
                                        Button("Edit", systemImage: "pencil") {
                                            editing = .author
                                        }
                                        .labelStyle(.iconOnly)
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
                .inspectorColumnWidth(ideal: 200)
                .toolbar {
                    Spacer()
                    Button("Show Inspector", systemImage: "sidebar.right") {
                        isShowingInspector.toggle()
                    }
                }
            }
            .onAppear {
                loadPDF()
            }
        }
    }
    
    func loadPDF() {
        loading = true
        // 从本地文件加载
        if let bookmark = paper.fileBookmark {
            Task {
                defer { loading = false }
                var bookmarkStale = false
                do {
                    let resolvedUrl = try URL(resolvingBookmarkData: bookmark,
                                              options: bookmarkResOptions,
                                              relativeTo: nil,
                                              bookmarkDataIsStale: &bookmarkStale)
                    let didStartAccessing = resolvedUrl.startAccessingSecurityScopedResource()
                    defer {
                        resolvedUrl.stopAccessingSecurityScopedResource()
                    }
                    
                    if bookmarkStale {
                        paper.fileBookmark = try resolvedUrl.bookmarkData(options: bookmarkCreationOptions)
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
            return
        }
        loading = false
        // 下载
        if let urlStr = paper.file, let url = URL(string: urlStr) {
            Task {
                do {
                    let localURL = try await downloadVM.downloadFile(from: url)
                    loading = true
                    let documentsURL = try FileManager.default.url(for: .documentDirectory,
                                                                   in: .userDomainMask,
                                                                   appropriateFor: nil,
                                                                   create: false)
                    let savedURL = documentsURL.appendingPathComponent("\(paper.id.uuidString).pdf")
                    try FileManager.default.moveItem(at: localURL, to: savedURL)
                    paper.fileBookmark = try savedURL.bookmarkData(options: bookmarkCreationOptions)
                    pdf = PDFDocument(url: savedURL)
                    errorDescription = nil
                } catch {
                    errorDescription = String(localized: "Failed to download PDF: ") + error.localizedDescription
                }
                loading = false
            }
        }
    }
    
    func handleImportFile(result: Result<URL, Error>) {
        loading = true
        Task {
            do {
                switch result {
                case .success(let url):
                    paper.file = url.path
                    let didStartAccessing = url.startAccessingSecurityScopedResource()
                    defer { url.stopAccessingSecurityScopedResource() }
                    if didStartAccessing {
                        paper.fileBookmark = try url.bookmarkData(options: bookmarkCreationOptions)
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
