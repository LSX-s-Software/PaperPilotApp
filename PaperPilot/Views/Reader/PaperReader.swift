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
    @State private var isDroping = false
    @State private var tocContent: TOCContentType = .none
    @State private var columnVisibility = NavigationSplitViewVisibility.detailOnly
    @State private var findVM = FindViewModel<PDFSelection>()
    @State private var pdfVM = PDFViewModel()
    @State private var downloadVM = DownloadViewModel()
    
    var body: some View {
        let pdfView = Binding(get: { pdfVM.pdfView }, set: { pdfVM.pdfView = $0 })
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
                        PDFKitThumbnailView(pdfView: pdfView, thumbnailWidth: 125)
#if os(visionOS)
                            .frame(depth: 100)
#endif
                    case .bookmark:
                        BookmarkView(pdf: pdf, bookmarks: $paper.bookmarks)
                    }
#if os(macOS) || os(visionOS)
                    if findVM.searchBarFocused && !findVM.findText.isEmpty {
                        FindResultView(findVM: findVM)
    #if os(macOS)
                            .background(
                                .windowBackground
                            )
    #else
    #endif
                    }
#endif
                }
            }
            .navigationTitle(LocalizedStringKey(tocContent.rawValue))
            .environment(pdfVM)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .navigationSplitViewColumnWidth(min: 250, ideal: 250)
#else
            .navigationSplitViewColumnWidth(min: 150, ideal: 175)
            .toolbar(removing: .sidebarToggle)
#endif
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
            HStack {
                Group {
                    if pdfVM.loading {
                        ProgressView()
                    } else if let pdf = pdfVM.pdf {
                        PDFReader(paper: paper, pdf: pdf, pdfVM: pdfVM)
                            .environment(findVM)
                    } else {
                        VStack(spacing: 6) {
                            Image(
                                systemName: downloadVM.downloading ?
                                "arrow.down.circle.fill" : "exclamationmark.triangle.fill"
                            )
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(downloadVM.downloading ? Color.accentColor : .red)
                            .font(.title)
                            .imageScale(.large)
                            if let errorDescription = errorDescription {
                                Text(errorDescription)
                                    .font(.title)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                            } else if paper.file == nil && paper.relativeLocalFile == nil {
                                Text("This paper has no PDF file attached.")
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                                VStack(spacing: 8) {
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
                                    
                                    Text("Or")
                                        .foregroundStyle(.secondary)
                                    
                                    VStack(spacing: 8) {
                                        Image(systemName: "arrow.down.doc.fill")
                                            .symbolRenderingMode(isDroping ? .monochrome : .hierarchical)
                                            .foregroundStyle(Color.accentColor)
                                            .imageScale(.large)
                                        Text("Drag and Drop PDF Here")
                                            .foregroundStyle(isDroping ? .primary : .secondary)
                                    }
                                    .font(.title2)
                                    .padding(40)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [5]))
                                            .foregroundStyle(isDroping ? .primary : .secondary)
                                    }
                                    .dropDestination(for: URL.self) { urls, _ in
                                        handleDropFile(urls: urls)
                                    } isTargeted: { targeted in
                                        withAnimation {
                                            isDroping = targeted
                                        }
                                    }
                                }
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
                                Text("Unknown error")
                                    .font(.title)
                            }
                        }
                    }
                }
#if os(visionOS)
                .frame(minWidth: 300)
#endif
#if os(visionOS)
                PaperReaderInspector(paper: paper)
                    .environment(pdfVM)
#endif
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // MARK: - 右侧内容
#if !os(visionOS)
            .inspector(isPresented: $isShowingInspector) {
                PaperReaderInspector(paper: paper)
                    .environment(pdfVM)
            }
            .inspectorColumnWidth(min: 250, ideal: 300)
#endif
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
        if let url = FilePath.paperFileURL(for: paper) {
            if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
                pdfVM.pdf = PDFDocument(url: url)
                tocContent = .outline
                columnVisibility = .all
                errorDescription = nil
            } else {
                paper.relativeLocalFile = nil
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
                if FileManager.default.fileExists(atPath: savedURL.path(percentEncoded: false)) {
                    try FileManager.default.removeItem(at: savedURL)
                }
                try FileManager.default.moveItem(at: localURL, to: savedURL)
                paper.relativeLocalFile = url.lastPathComponent
                paper.status = ModelStatus.normal.rawValue
                pdfVM.pdf = PDFDocument(url: savedURL)
                tocContent = .outline
                columnVisibility = .all
                errorDescription = nil
            } catch {
                errorDescription = String(localized: "Failed to download PDF: ") + error.localizedDescription
            }
        }
    }

    @discardableResult
    func importFile(url: URL, securityScoped: Bool = true) -> Bool {
        let didStartAccessing = !securityScoped || url.startAccessingSecurityScopedResource()
        defer {
            if securityScoped {
                url.stopAccessingSecurityScopedResource()
            }
        }
        if didStartAccessing {
            do {
                let savedURL = try FilePath.paperDirectory(for: paper, create: true)
                    .appending(path: url.lastPathComponent)
                if FileManager.default.fileExists(atPath: savedURL.path(percentEncoded: false)) {
                    try FileManager.default.removeItem(at: savedURL)
                }
                try FileManager.default.copyItem(at: url, to: savedURL)
                paper.relativeLocalFile = url.lastPathComponent
                if paper.project?.remoteId == nil {
                    paper.status = ModelStatus.normal.rawValue
                } else {
                    paper.status = ModelStatus.waitingForUpload.rawValue
                }
                pdfVM.pdf = PDFDocument(url: savedURL)
                tocContent = .outline
                columnVisibility = .all
                errorDescription = nil
                return true
            } catch {
                errorDescription = error.localizedDescription
                return false
            }
        } else {
            errorDescription = PDFError.noAccess.localizedDescription
            return false
        }
    }

    func handleImportFile(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            pdfVM.loading = true
            Task {
                importFile(url: url)
                pdfVM.loading = false
            }
        case .failure(let error):
            errorDescription = error.localizedDescription
        }
    }

    func handleDropFile(urls: [URL]) -> Bool {
        guard let url = urls.first(where: { $0.pathExtension == "pdf" }) else { return false }
        return importFile(url: url, securityScoped: false)
    }
}

#Preview {
    PaperReader(paper: ModelData.paper1)
        .environment(AppState())
#if os(macOS)
        .frame(width: 900, height: 600)
#endif
}
