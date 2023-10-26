//
//  PaperReader.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/25.
//

import SwiftUI
import PDFKit
import Throttler

private enum SidebarContent: String, Identifiable, CaseIterable {
    case info
    case note
    case translator

    var id: Self { self }
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .info: "Info"
        case .note: "Note"
        case .translator: "Translator"
        }
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
    @State private var newTitle = ""
    @State private var newAuthor = ""
    @State private var newAuthors = [String]()
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
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Group {
                            Text(paper.title)
                                .font(.title)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .overlay(alignment: .trailing) {
                                    if isShowingEditButton == .title {
                                        Button("Edit", systemImage: "pencil") {
                                            newTitle = paper.title
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
                                    TextField("Enter title", text: $newTitle)
                                        .padding()
                                        .onSubmit {
                                            if !newTitle.isEmpty {
                                                handleModifyPaper(newTitle: newTitle)
                                            }
                                        }
                                }

                            Text(paper.formattedAuthors)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .overlay(alignment: .trailing) {
                                    if isShowingEditButton == .author {
                                        Button("Edit", systemImage: "pencil") {
                                            newAuthors = paper.authors
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
                                        ForEach(newAuthors, id: \.self) { author in
                                            Text(author)
                                        }
                                        .onMove { source, destination in
                                            newAuthors.move(fromOffsets: source, toOffset: destination)
                                            handleModifyPaper(newAuthors: newAuthors)
                                        }
                                        .onDelete {
                                            newAuthors.remove(atOffsets: $0)
                                            handleModifyPaper(newAuthors: newAuthors)
                                        }
                                        Section("Add author") {
                                            TextField("New author", text: $newAuthor)
                                            Button("Add") {
                                                if !newAuthor.isEmpty {
                                                    newAuthors.append(newAuthor)
                                                    newAuthor = ""
                                                    handleModifyPaper(newAuthors: newAuthors)
                                                }
                                            }
                                            .keyboardShortcut(.defaultAction)
                                        }
                                    }
                                }
                        }
                        .multilineTextAlignment(.leading)

                        Picker("Sidebar Content", selection: $sidebarContent) {
                            ForEach(SidebarContent.allCases) { content in
                                Text(content.localizedStringKey).tag(content)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    .padding([.horizontal, .top])

                    switch sidebarContent {
                    case .info:
                        PaperInfo(paper: paper)
                    case .note:
                        TextEditor(text: $paper.note)
                    case .translator:
                        TranslatorView(viewModel: translatorVM)
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
            .task(id: paper.id) {
                await loadPDF()
                await ModelService.shared.setPaperRead(paper, read: true)
            }
        }
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

    func handleModifyPaper(newTitle: String? = nil, newAuthors: [String]? = nil) {
        if newTitle == nil && newAuthors == nil { return }
        Task {
            do {
                try await ModelService.shared.updatePaper(paper, title: newTitle, authors: newAuthors)
                editing = .none
            } catch {
                print(error)
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
