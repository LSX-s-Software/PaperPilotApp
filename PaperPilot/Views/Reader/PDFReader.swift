//
//  PDFReader.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/11.
//

import SwiftUI
import SwiftData
import PDFKit
import ShareKit
import Combine
import PencilKit

struct PDFReader: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(FindViewModel<PDFSelection>.self) private var findVM

    @AppStorage(AppStorageKey.User.id.rawValue)
    private var userId: String = ""

    @Bindable var paper: Paper
    var pdf: PDFDocument
    @ObservedObject var pdfVM: PDFViewModel
    var isRemote: Bool { paper.remoteId != nil }

    @State private var annotationColor = HighlighterColor.yellow
    @State private var isInMarkUpMode = false
    private var pageBookmarked: Bool {
        let page = pdf.index(for: pdfVM.currentPage)
        return paper.bookmarks.contains { $0.page == page }
    }

    @State private var savingPDF = false
    @State private var saveErrorMsg: LocalizedStringKey?
    @State private var isShowingSaveErrorDetail = false

    // 协作
    @State private var connecting = true
    @State private var shareDocument: ShareDocument<SharedAnnotation>?
    @State private var sharedAnnotation = SharedAnnotation()
    @State private var shareErrorMsg: String?
    @State private var bag = Set<AnyCancellable>()
    let dateFormatter = ISO8601DateFormatter()

    var body: some View {
        @Bindable var findVM = findVM

        PDFKitView(pdf: pdf, pdfView: $pdfVM.pdfView, markupMode: $isInMarkUpMode)
            .navigationDocument(pdf.documentURL!)
#if os(macOS)
            .searchable(text: $findVM.findText, isPresented: $findVM.searchBarPresented, prompt: Text("Find in PDF"))
            .navigationSubtitle("Page: \(pdfVM.currentPage.label ?? "Unknown")/\(pdf.pageCount)")
#elseif os(iOS)
            .sheet(isPresented: $findVM.isShowingFindSheet) {
                NavigationStack {
                    FindResultView(findVM: findVM)
                        .environmentObject(pdfVM)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    findVM.isShowingFindSheet = false
                                }
                            }
                        }
                }
                .searchable(text: $findVM.findText, isPresented: $findVM.searchBarPresented, prompt: Text("Find in PDF"))
            }
            .ignoresSafeArea(edges: .bottom)
#endif
            // MARK: - 事件处理
            .onChange(of: findVM.findText, performFind)
            .onChange(of: appState.findingPaper, findInPDFHandler)
            .onChange(of: findVM.searchBarPresented) {
                if !findVM.searchBarPresented && findVM.findText.isEmpty {
                    appState.findingPaper.remove(paper.id)
                }
            }
            .onSubmit(of: .search) {
                if findVM.findResult.isEmpty {
                    performFind()
                } else {
                    findVM.currentSelectionIndex = (findVM.currentSelectionIndex + 1) % findVM.findResult.count
                    let nextSelection = findVM.findResult[findVM.currentSelectionIndex]
                    pdfVM.pdfView.go(to: nextSelection)
                    pdfVM.pdfView.setCurrentSelection(nextSelection, animate: true)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .PDFViewPageChanged)) { _ in
                if let currentPage = pdfVM.pdfView.currentPage {
                    pdfVM.currentPage = currentPage
                }
            }
            // MARK: - 工具栏
            .toolbar(id: "reader-tools") {
                // MARK: 搜索选项
#if os(macOS)
                if findVM.searchBarPresented {
                    ToolbarItem(id: "search") {
                        Menu("Find Options", systemImage: "doc.text.magnifyingglass") {
                            Toggle("Case Sensitive", systemImage: "textformat", isOn: $findVM.caseSensitive)
                        }
                        .onChange(of: findVM.findOptions, performFind)
                    }
                }
#else
                ToolbarItem(id: "search", placement: .topBarTrailing) {
                    Button("Search", systemImage: "magnifyingglass") {
                        findVM.isShowingFindSheet.toggle()
                    }
                }

                ToolbarItem(id: "markup") {
                    Button("Markup", systemImage: "pencil.tip.crop.circle") {
                        isInMarkUpMode.toggle()
                    }
                    .symbolVariant(isInMarkUpMode ? .fill : .none)
                }
#endif
                ToolbarItem(id: "annotation") {
                    // MARK: 标注
                    ControlGroup {
                        Picker("Highlighter Color", selection: $annotationColor) {
                            ForEach(HighlighterColor.allCases) { color in
                                HStack {
                                    Image(systemName: "largecircle.fill.circle")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(color.color)
                                    Text(LocalizedStringKey(color.rawValue))
                                }
                                .tag(color)
                            }
                        }
                        Button("Highlight", systemImage: "highlighter") {
                            handleAddAnnotation(.highlight)
                        }
                        Button("Underline", systemImage: "underline") {
                            handleAddAnnotation(.underline)
                        }
                    }
                }

                ToolbarItem(id: "bookmark") {
                    Button("Add to bookmark", systemImage: "bookmark") {
                        handleToggleBookmark()
                    }
                    .symbolVariant(pageBookmarked ? .fill : .none)
                }

                ToolbarItem(id: "timer") {
                    TimerView()
                }
            }
            .toolbarRole(.editor)
            // MARK: - 底部叠层
            .overlay(alignment: .bottom) {
                Group {
                    if savingPDF {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.mini)
                            Text("Saving")
                                .foregroundStyle(.secondary)
                        }
                    } else if let errorMsg = saveErrorMsg {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                            Text("Failed to save PDF")
                        }
                        .onTapGesture {
                            isShowingSaveErrorDetail.toggle()
                        }
                        .popover(isPresented: $isShowingSaveErrorDetail) {
                            HStack {
                                Text(errorMsg)
                                Button {
                                    saveErrorMsg = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.plain)
                            }
                            .padding()
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .overlay(alignment: .bottomLeading) {
                if isRemote {
                    OnlineIndicator(loading: connecting, online: shareDocument != nil, errorMsg: shareErrorMsg)
                        .offset(x: 20, y: -20)
                }
            }
            .onAppear {
                if let currentPage = pdfVM.pdfView.currentPage {
                    pdfVM.currentPage = currentPage
                }
            }
            .onDisappear {
                if !isRemote {
                    Task {
                        if let url = pdf.documentURL {
                            if !pdf.writeWithMarkup(to: url) {
                                print("Failed to write PDF.")
                            }
                        } else {
                            print("You don't have access to the PDF.")
                        }
                    }
                }
            }
            .task(id: paper.id) {
                guard let id = paper.remoteId else { return }
                await ShareCoordinator.shared.connect()
                do {
                    shareDocument = try await ShareCoordinator.shared.getDocument(id, in: .annotations)
                    if await shareDocument!.notCreated {
                        try await shareDocument!.create(SharedAnnotation())
                    }
                    await shareDocument!.value
                        .compactMap { $0 }
                        .receive(on: RunLoop.main)
                        .sink { newAnnotations in
                            let oldKeys = sharedAnnotation.annotations.keys
                            let newKeys = newAnnotations.annotations.keys
                            // 新增
                            Set(newKeys).subtracting(oldKeys).forEach { key in
                                if let annotation = newAnnotations.annotations[key] {
                                    sharedAnnotation.pdfAnnotations[key] = addAnnotation(annotation)
                                }
                            }
                            Set(oldKeys).subtracting(newKeys).forEach { key in
                                if let annotation = sharedAnnotation.pdfAnnotations[key],
                                   let page = sharedAnnotation.annotations[key]?.page,
                                   let pdfPage = pdf.page(at: page) {
                                    pdfPage.removeAnnotation(annotation)
                                    sharedAnnotation.pdfAnnotations.removeValue(forKey: key)
                                }
                            }
                            sharedAnnotation.annotations = newAnnotations.annotations
                        }
                        .store(in: &bag)
                } catch {
                    print("init error:", error)
                    shareErrorMsg = error.localizedDescription
                }
                connecting = false
            }
    }
}

// MARK: - PDF查找
extension PDFReader {
    func findInPDFHandler() {
        if appState.findingPaper.contains(paper.id) {
            findVM.focusSearchBar()
        } else {
            findVM.reset()
        }
    }

    private func performFind() {
        guard !findVM.finding else { return }
        if findVM.findText.isEmpty {
            findVM.finding = false
            appState.findingPaper.remove(paper.id)
            return
        }
        findVM.finding = true
        appState.findingPaper.insert(paper.id)
        Task {
            findVM.findResult = pdf.findString(findVM.findText, withOptions: findVM.findOptions)
            findVM.finding = false
            if let firstResult = findVM.findResult.first {
                findVM.currentSelectionIndex = 0
                pdfVM.pdfView.setCurrentSelection(firstResult, animate: true)
            }
        }
    }
}

// MARK: - PDF标注
extension PDFReader {
    func addAnnotation(_ annotation: SharedAnnotation.Annotation) -> PDFAnnotation? {
        guard let page = pdf.page(at: annotation.page) else { return nil }
        let type = PDFAnnotationSubtype(rawValue: annotation.type)
        let newAnnotation = PDFAnnotation(bounds: annotation.bounds, forType: type, withProperties: nil)
        newAnnotation.color = annotation.color.color
        page.addAnnotation(newAnnotation)
        return newAnnotation
    }

    func handleAddAnnotation(_ type: PDFAnnotationSubtype) {
        guard let select = pdfVM.pdfView.currentSelection?.selectionsByLine() else { return }
        select.forEach { selection in
            if let page = selection.pages.first {
                let bounds = selection.bounds(for: page)
                let newPDFAnnotation = PDFAnnotation(bounds: bounds,
                                                     forType: type,
                                                     withProperties: nil)
                newPDFAnnotation.color = annotationColor.platformColor
                page.addAnnotation(newPDFAnnotation)

                if isRemote {
                    let uuid = UUID().uuidString
                    let newSharedAnnotation = SharedAnnotation.Annotation(page: pdf.index(for: page),
                                                                          bounds: bounds,
                                                                          type: type.rawValue,
                                                                          color: .init(annotationColor.platformColor),
                                                                          authorId: userId)
                    sharedAnnotation.annotations[uuid] = newSharedAnnotation
                    sharedAnnotation.pdfAnnotations[uuid] = newPDFAnnotation
                }
            }
        }

        if isRemote {
            // 远程论文发送到ShareDB
            Task {
                do {
                    try await shareDocument?.change {
                        try $0.annotations.set(sharedAnnotation.annotations)
                    }
                } catch {
                    print("update error:", error)
                    shareErrorMsg = error.localizedDescription
                }
            }
        } else {
            // 本地论文直接写入PDF
            withAnimation {
                savingPDF = true
            }
            Task {
                if let url = pdf.documentURL {
                    if !pdf.write(to: url) {
                        saveErrorMsg = "Failed to write PDF."
                    }
                } else {
                    saveErrorMsg = "You don't have access to the PDF."
                }
                withAnimation {
                    savingPDF = false
                }
            }
        }
    }

    func handleToggleBookmark() {
        let pageIndex = pdf.index(for: pdfVM.currentPage)
        if pageBookmarked {
            if let index = paper.bookmarks.firstIndex(where: { $0.page == pageIndex }) {
                let bookmark = paper.bookmarks[index]
                paper.bookmarks.remove(at: index)
                modelContext.delete(bookmark)
            }
        } else {
            let bookmark = Bookmark(page: pageIndex, label: pdfVM.currentPage.label)
            paper.bookmarks.append(bookmark)
        }
    }
}

#Preview {
    PDFReader(paper: ModelData.paper1,
              pdf: PDFDocument(url: Bundle.main.url(forResource: "sample", withExtension: "pdf")!)!,
              pdfVM: PDFViewModel())
    .environment(AppState())
    .modelContainer(previewContainer)
    .frame(width: 800)
}
