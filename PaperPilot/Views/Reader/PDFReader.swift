//
//  PDFReader.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/11.
//

import SwiftUI
import SwiftData
import PDFKit

struct PDFReader: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var findVM: FindViewModel<PDFSelection>

    @Bindable var paper: Paper
    var pdf: PDFDocument
    @ObservedObject var pdfVM: PDFViewModel

    @State private var annotationColor = HighlighterColor.yellow
    private var pageBookmarked: Bool {
        guard let page = pdfVM.pdf?.index(for: pdfVM.currentPage) else { return false }
        return paper.bookmarks.contains { $0.page == page }
    }

    @State private var savingPDF = false
    @State private var saveErrorMsg: LocalizedStringKey?
    @State private var isShowingSaveErrorDetail = false

    var body: some View {
        PDFKitView(pdf: pdf, pdfView: $pdfVM.pdfView)
            .searchable(text: $findVM.findText, isPresented: $findVM.searchBarPresented, prompt: Text("Find in PDF"))
            .navigationDocument(pdf.documentURL!)
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
#if os(macOS)
            .navigationSubtitle("Page: \(pdfVM.currentPage.label ?? "Unknown")/\(pdf.pageCount)")
#endif
        // MARK: - 工具栏
            .toolbar {
                // MARK: 搜索选项
                if findVM.searchBarPresented {
                    ToolbarItem {
                        Menu("Find Options", systemImage: "doc.text.magnifyingglass") {
                            Toggle("Case Sensitive", systemImage: "textformat", isOn: $findVM.caseSensitive)
                        }
                        .onChange(of: findVM.findOptions, performFind)
                    }
                }
                ToolbarItemGroup(placement: .principal) {
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
                    Button("Add to bookmark", systemImage: "bookmark") {
                        handleToggleBookmark()
                    }
                    .symbolVariant(pageBookmarked ? .fill : .none)

                    Spacer()

                    // MARK: 计时器
                    TimerView()
                }
            }
            .onAppear {
                if let currentPage = pdfVM.pdfView.currentPage {
                    pdfVM.currentPage = currentPage
                }
            }
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
        guard let pdf = pdfVM.pdf, !findVM.finding else { return }
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
    func handleAddAnnotation(_ type: PDFAnnotationSubtype) {
        let select = pdfVM.pdfView.currentSelection?.selectionsByLine()
        select?.forEach { selection in
            if let page = selection.pages.first {
                let bounds = selection.bounds(for: page)
                let highlight = PDFAnnotation(bounds: bounds,
                                              forType: type,
                                              withProperties: nil)
#if os(macOS)
                highlight.color = NSColor(annotationColor.color)
#else
                highlight.color = UIColor(annotationColor.color)
#endif
                page.addAnnotation(highlight)
            }
        }

        withAnimation {
            savingPDF = true
        }
        Task {
            if let pdf = pdfVM.pdf, let url = pdf.documentURL {
                if !pdf.write(to: url) {
                    saveErrorMsg = "Failed to write PDF."
                }
            } else {
                saveErrorMsg = "You don't have access to the PDF."
            }
            DispatchQueue.main.async {
                withAnimation {
                    savingPDF = false
                }
            }
        }
    }

    func handleToggleBookmark() {
        guard let pdf = pdfVM.pdf else { return }
        let pageIndex = pdf.index(for: pdfVM.currentPage)
        if pageBookmarked {
            paper.bookmarks.removeAll { $0.page == pageIndex }
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
