//
//  PDFReader.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/11.
//

import SwiftUI
import SwiftData
import PDFKit

private enum TOCContentType: String, Identifiable, CaseIterable {
    case none = "Hide TOC"
    case outline = "Outline"
    case thumbnail = "Thumbnail"
    case bookmark = "Bookmark"
    
    var id: Self { self }
}

struct PDFReader: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) var modelContext
    
    @Bindable var paper: Paper
    let pdf: PDFDocument
    
    @State private var pdfView = PDFView()
    @State private var tocContent: TOCContentType = .outline
    @State private var currentPage = PDFPage()
    @State private var currentSelection: PDFSelection?
    @State private var findText = ""
    @State private var searchBarPresented = false
    @State private var caseSensitive = false
    @State private var finding = false
    @State private var findResult = [PDFSelection]()
    var findOptions: NSString.CompareOptions {
        var options: NSString.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        if caseSensitive {
            options.remove(.caseInsensitive)
        }
        return options
    }
    
    @State private var annotationColor = HighlighterColor.yellow
    private var currentPageBookmarked: Bool {
        let page = pdf.index(for: currentPage)
        return paper.bookmarks.contains { $0.page == page }
    }
    
    @State private var savingPDF = false
    @State private var saveErrorMsg: LocalizedStringKey?
    @State private var isShowingSaveErrorDetail = false

    var onSelection: ((PDFSelection?) -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            // MARK: - 侧边栏
            VStack(spacing: 0) {
                if searchBarPresented && !findText.isEmpty {
                    List(findResult, id: \.self, selection: Binding { currentSelection } set: { selection in
                        if let page = selection?.pages.first {
                            pdfView.go(to: page)
                        }
                        pdfView.setCurrentSelection(selection, animate: true)
                    }) { selection in
                        HStack {
                            VStack(alignment: .leading) {
                                if let page = selection.pages.first?.label {
                                    Text("Page \(page)")
                                        .font(.caption)
                                }
                                Text(findResultText(for: selection))
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .padding(.bottom, 8)
                        .tag(selection)
                    }
                    .listStyle(.sidebar)
                    .animation(.easeInOut, value: finding)
                    .frame(width: 175)
                    .overlay {
                        if finding {
                            VStack(spacing: 8) {
                                ProgressView()
                                Text("Finding...")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else if findResult.isEmpty {
                            Text("No Results")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    switch tocContent {
                    case .none:
                        EmptyView()
                    case .outline:
                        Group {
                            if let root = pdf.outlineRoot {
                                PDFOutlineView(root: root, selection: Binding {
                                    currentPage
                                } set: {
                                    if let page = $0 {
                                        pdfView.go(to: page)
                                    }
                                })
                            } else {
                                Text("No Outline")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 175)
                    case .thumbnail:
                        PDFKitThumbnailView(pdfView: $pdfView, thumbnailWidth: 125)
                            .frame(width: 175)
                    case .bookmark:
                        List(
                            paper.bookmarks, id: \.page, selection: Binding {
                                pdf.index(for: currentPage)
                            } set: {
                                pdfView.go(to: pdf.page(at: $0!)!)
                            }
                        ) { bookmark in
                            HStack {
                                if let page = pdf.page(at: bookmark.page) {
#if os(macOS)
                                    Image(nsImage: page.thumbnail(of: NSSize(width: 180, height: 360), for: .trimBox))
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        .frame(maxWidth: 60, maxHeight: 120)
                                        .overlay(alignment: .topTrailing) {
                                            Image(systemName: "bookmark.fill")
                                                .foregroundStyle(Color.accentColor)
                                        }
#else
                                    Image(uiImage: page.thumbnail(of: CGSize(width: 180, height: 360), for: .trimBox))
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        .frame(maxWidth: 60, maxHeight: 120)
                                        .overlay(alignment: .topTrailing) {
                                            Image(systemName: "bookmark.fill")
                                                .foregroundStyle(Color.accentColor)
                                        }

#endif
                                    Spacer()
                                }
                                Text("Page \(bookmark.label ?? String(bookmark.page + 1))")
                                    .fontWeight(.medium)
                            }
                            .tag(bookmark)
                        }
                        .listStyle(.sidebar)
                        .frame(width: 150)
                    }
                }
                
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
            
            // MARK: - 阅读器
            PDFKitView(pdf: pdf, pdfView: $pdfView)
                .searchable(text: $findText, isPresented: $searchBarPresented, prompt: Text("Find in PDF"))
                .navigationDocument(pdf.documentURL!)
                .onChange(of: findText, performFind)
                .onSubmit(of: .search) {
                    if findResult.isEmpty {
                        performFind()
                    } else if let selection = currentSelection,
                              let selectionIndex = findResult.firstIndex(of: selection) {
                        let nextIndex = (selectionIndex + 1) % findResult.count
                        currentSelection = findResult[nextIndex]
                        pdfView.go(to: selection)
                        pdfView.setCurrentSelection(selection, animate: true)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .PDFViewPageChanged)) { _ in
                    if let page = pdfView.currentPage {
                        currentPage = page
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .PDFViewSelectionChanged)) { _ in
                    if !searchBarPresented || findText.isEmpty {
                        currentSelection = pdfView.currentSelection
                        onSelection?(pdfView.currentSelection)
                    }
                }
        }
        .animation(.easeInOut, value: tocContent)
#if os(macOS)
        .navigationSubtitle("Page: \(currentPage.label ?? "Unknown")/\(pdf.pageCount)")
#endif
        // MARK: - 工具栏
        .toolbar {
            // MARK: 目录
            ToolbarItem(placement: .navigation) {
                Menu("Table of Contents", systemImage: "sidebar.squares.left") {
                    Picker("Table of Contents", selection: $tocContent) {
                        ForEach(TOCContentType.allCases) { type in
                            Text(LocalizedStringKey(type.rawValue)).tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            // MARK: 搜索选项
            if searchBarPresented {
                ToolbarItem {
                    Menu("Find Options", systemImage: "doc.text.magnifyingglass") {
                        Toggle("Case Sensitive", systemImage: "textformat", isOn: $caseSensitive)
                    }
                    .onChange(of: findOptions, performFind)
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
                .symbolVariant(currentPageBookmarked ? .fill : .none)

                Spacer()
                
                // MARK: 计时器
                TimerView()
            }
        }
        .onAppear {
            appState.findInPDFHandler = findInPDFHandler(_:)
            if let page = pdfView.currentPage {
                currentPage = page
            }
        }
    }
}
    
// MARK: - PDF查找
extension PDFReader {
    func findInPDFHandler(_ shouldFind: Bool) {
        if shouldFind {
            searchBarPresented = true
        } else {
            searchBarPresented = false
            findText = ""
            finding = false
            findResult.removeAll()
            appState.findingInPDF = false
        }
    }
    
    private func performFind() {
        if finding || findText.isEmpty {
            finding = false
            return
        }
        finding = true
        appState.findingInPDF = true
        Task {
            findResult = pdf.findString(findText, withOptions: findOptions)
            finding = false
            if let firstResult = findResult.first {
                pdfView.setCurrentSelection(firstResult, animate: true)
                currentSelection = firstResult
            }
        }
    }
    
    private func findResultText(for selection: PDFSelection) -> AttributedString {
        guard let extendSelection = selection.copy() as? PDFSelection else { return "" }
        extendSelection.extendForLineBoundaries()
        var attributedString = AttributedString(extendSelection.string ?? "")
        guard let range = attributedString.range(of: selection.string ?? "", options: findOptions) else { return "" }
        attributedString[range].inlinePresentationIntent = .stronglyEmphasized
        attributedString[range].foregroundColor = .yellow
        return attributedString
    }
}

// MARK: - PDF标注
extension PDFReader {
    func handleAddAnnotation(_ type: PDFAnnotationSubtype) {
        let select = pdfView.currentSelection?.selectionsByLine()
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
            if let url = pdf.documentURL {
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
        let page = pdf.index(for: currentPage)
        if currentPageBookmarked {
            paper.bookmarks.removeAll { $0.page == page }
        } else {
            let bookmark = Bookmark(page: page, label: currentPage.label)
            paper.bookmarks.append(bookmark)
        }
    }
}

#Preview {
    PDFReader(paper: ModelData.paper1,
              pdf: PDFDocument(url: Bundle.main.url(forResource: "sample", withExtension: "pdf")!)!)
        .environmentObject(AppState())
        .modelContainer(previewContainer)
        .frame(width: 800)
}
