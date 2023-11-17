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
    @Bindable var pdfVM: PDFViewModel
    var isRemote: Bool { paper.remoteId != nil }

    @State private var annotationColor = HighlighterColor.yellow
    @State private var isInMarkUpMode = false
    private var pageBookmarked: Bool {
        let page = pdf.index(for: pdfVM.currentPage)
        return paper.bookmarks.contains { $0.page == page }
    }

    @State private var savingPDF = false
    @State private var saveError: LocalizedError?

    // 协作
    @State private var connecting = true
    @State private var sharedAnnotationDoc: ShareDocument<SharedAnnotation>?
    @State private var sharedCanvasDoc: ShareDocument<SharedCanvas>?
    @State private var sharedAnnotation = SharedAnnotation()
    @State private var sharedCanvas = SharedCanvas()
    @State private var shareErrorMsg: String?
    @State private var bag = Set<AnyCancellable>()

    var body: some View {
        @Bindable var findVM = findVM

        PDFKitView(pdf: pdf, pdfView: $pdfVM.pdfView, markupMode: $isInMarkUpMode, drawingChanged: handleDrawingChanged)
            .navigationDocument(pdf.documentURL!)
#if os(macOS)
            .navigationSubtitle("Page: \(pdfVM.currentPage.label ?? "Unknown")/\(pdf.pageCount)")
#endif
#if os(macOS) || os(visionOS)
            .searchable(text: $findVM.findText, isPresented: $findVM.searchBarFocused, prompt: Text("Find in PDF"))
#elseif os(iOS)
            .sheet(isPresented: $findVM.isShowingFindSheet) {
                NavigationStack {
                    FindResultView(findVM: findVM)
                        .environment(pdfVM)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    findVM.isShowingFindSheet = false
                                }
                            }
                        }
                }
                .searchable(text: $findVM.findText, isPresented: $findVM.searchBarFocused, prompt: Text("Find in PDF"))
            }
            .ignoresSafeArea(edges: .bottom)
#endif
            // MARK: - 事件处理
            .onChange(of: findVM.findText, performFind)
            .onChange(of: appState.findingPaper, findInPDFHandler)
            .onChange(of: findVM.searchBarFocused) {
                if !findVM.searchBarFocused && findVM.findText.isEmpty {
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
#if os(macOS) || os(visionOS)
                if findVM.searchBarFocused {
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
                // MARK: 标注
                ToolbarItem(id: "annotation") {
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
                if savingPDF || saveError != nil {
                    HStack(spacing: 6) {
                        if savingPDF {
                            ProgressView()
                                .controlSize(.mini)
                            Text("Saving")
                                .foregroundStyle(.secondary)
                        } else if let saveError = saveError {
                            Group {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Failed to save PDF: \(saveError.localizedDescription)")
                            }
                            .foregroundStyle(.red)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if isRemote {
                    OnlineIndicator(loading: connecting, online: sharedAnnotationDoc != nil, errorMsg: shareErrorMsg)
                        .offset(x: 20, y: -20)
                }
            }
            .onAppear {
                if let currentPage = pdfVM.pdfView.currentPage {
                    pdfVM.currentPage = currentPage
                }
            }
#if os(iOS)
            .onDisappear {
                if !isRemote, let url = pdf.documentURL, !pdf.writeWithMarkup(to: url) {
                    print("Failed to write PDF.")
                }
            }
#endif
            // MARK: - 协作
            .task(id: paper.id) {
                guard let id = paper.remoteId else { return }
                await ShareCoordinator.shared.connect()
                do {
                    // 标注
                    sharedAnnotationDoc = try await ShareCoordinator.shared.getDocument(id, in: .annotations)
                    if await sharedAnnotationDoc!.notCreated {
                        try await sharedAnnotationDoc!.create(SharedAnnotation())
                    }
                    await sharedAnnotationDoc!.value
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
                            // 删除
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
                    // 绘图
                    sharedCanvasDoc = try await ShareCoordinator.shared.getDocument(id, in: .canvas)
                    if await sharedCanvasDoc!.notCreated {
                        try await sharedCanvasDoc!.create(SharedCanvas())
                    }
                    await sharedCanvasDoc!.value
                        .compactMap { $0 }
                        .receive(on: RunLoop.main)
                        .sink { newCanvas in
                            for (page, canvas) in newCanvas.canvas {
                                if canvas == sharedCanvas.canvas[page] { continue }
                                if canvas.drawing != sharedCanvas.canvas[page]?.drawing,
                                   let drawedPage = pdf.page(at: page) as? DrawedPDFPage {
                                    drawedPage.drawing = canvas.drawing
#if os(macOS)
                                    if let annotation = PKPDFAnnotation(page: drawedPage, drawing: canvas.drawing) {
                                        drawedPage.annotations
                                            .filter { $0.type == PKPDFAnnotation.subtypeString }
                                            .forEach { drawedPage.removeAnnotation($0) }
                                        drawedPage.addAnnotation(annotation)
                                    }
#else
                                    if let coordinator = pdfVM.pdfView.pageOverlayViewProvider as? PDFKitView.Coordinator {
                                        coordinator.updateDrawing(for: drawedPage)
                                    }
#endif
                                }
                                sharedCanvas.canvas[page] = canvas
                            }
                        }
                        .store(in: &bag)
                } catch {
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
            findVM.isShowingFindSheet = true
            findVM.searchBarFocused = true
        } else {
            findVM.reset()
            findVM.searchBarFocused = false
            findVM.isShowingFindSheet = false
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
                await pdfVM.pdfView.go(to: firstResult)
                await pdfVM.pdfView.setCurrentSelection(firstResult, animate: true)
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
                let newPDFAnnotation = PDFAnnotation(bounds: bounds, forType: type, withProperties: nil)
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
                    try await sharedAnnotationDoc?.change {
                        try $0.annotations.set(sharedAnnotation.annotations)
                    }
                } catch {
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
                        saveError = PDFError.writeFailed
                    }
                } else {
                    saveError = PDFError.noAccess
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

    func handleDrawingChanged(page: PDFPage, drawing: PKDrawing) {
        #if os(iOS)
        guard isRemote else { return }
        let pageIndex = pdf.index(for: page)
        if sharedCanvas.canvas[pageIndex] != nil {
            sharedCanvas.canvas[pageIndex]!.drawing = drawing
            sharedCanvas.canvas[pageIndex]!.authorId = userId
        } else {
            sharedCanvas.canvas[pageIndex] = SharedCanvas.Canvas(drawing: drawing, authorId: userId)
        }
        Task {
            do {
                try await sharedCanvasDoc?.change {
                    try $0.canvas.set(sharedCanvas.canvas)
                }
            } catch {
                shareErrorMsg = error.localizedDescription
            }
        }
        #endif
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
