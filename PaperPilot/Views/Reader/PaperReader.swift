//
//  PaperReader.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/25.
//

import SwiftUI
import PDFKit
import Throttler

struct PaperReader: View {
    @Bindable var paper: Paper

    @AppStorage(AppStorageKey.Reader.isShowingInspector.rawValue)
    private var isShowingInspector = true

    @State private var loading = true
    @State private var errorDescription: String?
    @State private var pdf: PDFDocument?
    @State private var isImporting = false
    @StateObject private var translatorVM = TranslatorViewModel()
    @StateObject private var downloadVM = DownloadViewModel()

    var body: some View {
        NavigationStack {
            // MARK: - 左侧内容
            HStack {
                Group {
                    if loading {
                        ProgressView()
                    } else if let pdf = pdf {
                        PDFReader(paper: paper, pdf: pdf) { selection in
                            if translatorVM.translateBySelection,
                               let selection = selection?.string {
                                debounce {
                                    translatorVM.originalText = translatorVM.trimNewlines
                                    ? selection.trimmingCharacters(in: .newlines)
                                    : selection
                                }
                            }
                        }
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
            }
            .navigationTitle(paper.title)
            // MARK: - 右侧内容
            .inspector(isPresented: $isShowingInspector) {
                PaperReaderInspector(paper: paper)
                    .environmentObject(translatorVM)
            }
            .task(id: paper.id) {
                await loadPDF()
                await ModelService.shared.setPaperRead(paper, read: true)
            }
        }
        .focusedSceneValue(\.selectedPaper, .constant(paper))
    }
}

extension PaperReader {
    func loadPDF() async {
        loading = true
        defer { loading = false }
        // 从本地文件加载
        if let url = paper.localFile {
            if FileManager.default.isReadableFile(atPath: url.path()) {
                pdf = PDFDocument(url: url)
            } else {
                paper.localFile = nil
                errorDescription = String(localized: "Failed to load PDF: ") + String(localized: "File not found")
            }
            return
        }
        loading = false
        // 下载
        if let urlStr = paper.file, let url = URL(string: urlStr) {
            do {
                let localURL = try await downloadVM.downloadFile(from: url)
                loading = true
                let savedURL = try FilePath.paperDirectory(for: paper, create: true)
                    .appending(path: url.lastPathComponent)
                try FileManager.default.moveItem(at: localURL, to: savedURL)
                paper.localFile = savedURL
                paper.status = ModelStatus.normal.rawValue
                pdf = PDFDocument(url: savedURL)
                errorDescription = nil
            } catch {
                errorDescription = String(localized: "Failed to download PDF: ") + error.localizedDescription
            }
        }
    }
    
    func handleImportFile(result: Result<URL, Error>) {
        loading = true
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
                        pdf = PDFDocument(url: savedURL)
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
