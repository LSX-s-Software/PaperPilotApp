//
//  PaperReader.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/25.
//

import SwiftUI
import PDFKit
import Throttler

private enum TOCContentType: String, Identifiable, CaseIterable {
    case none = "Hide TOC"
    case outline = "Outline"
    case thumbnail = "Thumbnail"
    case bookmark = "Bookmark"

    var id: Self { self }
}

struct PaperReader: View {
    @Bindable var paper: Paper

    @AppStorage(AppStorageKey.Reader.isShowingInspector.rawValue)
    private var isShowingInspector = true

    @State private var errorDescription: String?
    @State private var isImporting = false
    @State private var tocContent: TOCContentType = .outline
    @State private var columnVisibility = NavigationSplitViewVisibility.detailOnly
    @StateObject private var pdfVM = PDFViewModel()
    @StateObject private var translatorVM = TranslatorViewModel()
    @StateObject private var downloadVM = DownloadViewModel()
    @StateObject private var findVM = FindViewModel<PDFSelection>()

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // MARK: - 左侧内容
            ZStack {
                if let pdf = pdfVM.pdf {
                    switch tocContent {
                    case .none:
                        EmptyView()
                    case .outline:
                        PDFOutlineView(root: pdf.outlineRoot)
                    case .thumbnail:
                        PDFKitThumbnailView(pdfView: $pdfVM.pdfView, thumbnailWidth: 125)
                    case .bookmark:
                        BookmarkView(pdf: pdf, bookmarks: $paper.bookmarks)
                    }

                    if findVM.searchBarPresented && !findVM.findText.isEmpty {
                        FindResultView(findVM: findVM)
                            .background(.windowBackground)
                    }
                }
            }
            .environmentObject(pdfVM)
            .toolbar(removing: .sidebarToggle)
            .toolbar {
                ToolbarItem(placement: columnVisibility == .all ? .automatic : .navigation) {
                    Menu("Table of Contents", systemImage: "sidebar.squares.left") {
                        Picker("Table of Contents", selection: $tocContent) {
                            ForEach(TOCContentType.allCases) { type in
                                Text(LocalizedStringKey(type.rawValue)).tag(type)
                            }
                        }
                        .pickerStyle(.inline)
                        .onChange(of: tocContent) {
                            withAnimation {
                                if tocContent == .none {
                                    columnVisibility = .detailOnly
                                } else if columnVisibility == .detailOnly {
                                    columnVisibility = .all
                                }
                            }
                        }
                    }
                    .disabled(pdfVM.pdf == nil)
                }
            }
        } detail: {
            // MARK: - 中间内容
            Group {
                if pdfVM.loading {
                    ProgressView()
                } else if let pdf = pdfVM.pdf {
                    PDFReader(paper: paper, pdf: pdf, pdfVM: pdfVM)
                        .environmentObject(findVM)
                } else {
                    VStack(spacing: 6) {
                        Image(
                            systemName: downloadVM.downloading ?
                            "arrow.down.circle.fill" : "exclamationmark.triangle.fill"
                        )
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(downloadVM.downloading ? Color.accentColor : .red)
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
            // MARK: - 右侧内容
            .inspector(isPresented: $isShowingInspector) {
                PaperReaderInspector(paper: paper)
                    .environmentObject(pdfVM)
                    .environmentObject(translatorVM)
            }
        }
        .navigationTitle(paper.title)
        .task(id: paper.id) {
            await loadPDF()
            await ModelService.shared.setPaperRead(paper, read: true)
        }
        .focusedSceneValue(\.selectedPaper, .constant(paper))
    }
}

extension PaperReader {
    func loadPDF() async {
        pdfVM.loading = true
        defer { pdfVM.loading = false }
        // 从本地文件加载
        if let url = paper.localFile {
            if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
                pdfVM.pdf = PDFDocument(url: url)
                columnVisibility = .all
            } else {
                paper.localFile = nil
                errorDescription = String(localized: "Failed to load PDF: ") + String(localized: "File not found")
            }
            return
        }
        pdfVM.loading = false
        // 下载
        if let urlStr = paper.file, let url = URL(string: urlStr) {
            do {
                let localURL = try await downloadVM.downloadFile(from: url)
                pdfVM.loading = true
                let savedURL = try FilePath.paperDirectory(for: paper, create: true)
                    .appending(path: url.lastPathComponent)
                try FileManager.default.moveItem(at: localURL, to: savedURL)
                paper.localFile = savedURL
                paper.status = ModelStatus.normal.rawValue
                pdfVM.pdf = PDFDocument(url: savedURL)
                columnVisibility = .all
                errorDescription = nil
            } catch {
                errorDescription = String(localized: "Failed to download PDF: ") + error.localizedDescription
            }
        }
    }
    
    func handleImportFile(result: Result<URL, Error>) {
        pdfVM.loading = true
        Task {
            do {
                switch result {
                case .success(let url):
                    let didStartAccessing = url.startAccessingSecurityScopedResource()
                    defer { url.stopAccessingSecurityScopedResource() }
                    if didStartAccessing {
                        let savedURL = try FilePath.paperDirectory(for: paper, create: true)
                            .appending(path: url.lastPathComponent)
                        try FileManager.default.copyItem(at: url, to: savedURL)
                        paper.localFile = savedURL
                        if paper.project?.remoteId == nil {
                            paper.status = ModelStatus.normal.rawValue
                        } else {
                            paper.status = ModelStatus.waitingForUpload.rawValue
                        }
                        pdfVM.pdf = PDFDocument(url: savedURL)
                        errorDescription = nil
                    } else {
                        errorDescription = String(localized: "You don't have access to the PDF.")
                    }
                case .failure(let error):
                    throw error
                }
            } catch {
                errorDescription = error.localizedDescription
            }
            pdfVM.loading = false
        }
    }
}

#Preview {
    PaperReader(paper: ModelData.paper1)
#if os(macOS)
        .frame(width: 900, height: 600)
#endif
}
