//
//  PDFReader.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/11.
//

import SwiftUI
import PDFKit

private enum TOCContentType: String, Identifiable, CaseIterable {
    case none = "Hide TOC"
    case outline = "Outline"
    case thumbnail = "Thumbnail"
    
    var id: Self { self }
}

private enum HighlighterColor: String, CaseIterable, Identifiable {
    case yellow = "Yellow"
    case green = "Green"
    case blue = "Blue"
    case pink = "Pink"
    case purple = "Purple"
    case black = "Black"
    
    var id: Self { self }
    
    var color: NSColor {
        switch self {
        case .yellow:
            NSColor(red: 249 / 255.0, green: 205 / 255.0, blue: 110 / 255.0, alpha: 1)
        case .green:
            NSColor(red: 142 / 255.0, green: 197 / 255.0, blue: 115 / 255.0, alpha: 1)
        case .blue:
            NSColor(red: 121 / 255.0, green: 175 / 255.0, blue: 235 / 255.0, alpha: 1)
        case .pink:
            NSColor(red: 233 / 255.0, green: 103 / 255.0, blue: 138 / 255.0, alpha: 1)
        case .purple:
            NSColor(red: 191 / 255.0, green: 136 / 255.0, blue: 214 / 255.0, alpha: 1)
        case .black:
            NSColor.black
        }
    }
}

struct PDFReader: View {
    @EnvironmentObject var appState: AppState
    
    let pdf: PDFDocument
    
    @State private var pdfView = PDFView()
    @State private var tocContent: TOCContentType = .outline
    @State private var currentPage: String? = "1"
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
    
    var body: some View {
        HStack {
            // MARK: - 侧边栏
            if searchBarPresented && !findText.isEmpty {
                List(findResult, id: \.self) { selection in
                    Button {
                        if let page = selection.pages.first {
                            pdfView.go(to: page)
                        }
                        pdfView.setCurrentSelection(selection, animate: true)
                    } label: {
                        VStack(alignment: .leading) {
                            if let page = selection.pages.first?.label {
                                Text("Page \(page)")
                                    .font(.caption)
                            }
                            Text(findResultText(for: selection))
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .buttonStyle(.link)
                    .padding(.bottom, 8)
                }
                .listStyle(.sidebar)
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
                .animation(.easeInOut, value: finding)
                .frame(width: 175)
            } else {
                switch tocContent {
                case .none:
                    EmptyView()
                case .outline:
                    Group {
                        if let root = pdf.outlineRoot {
                            PDFOutlineView(root: root) { page in
                                pdfView.go(to: page)
                            }
                        } else {
                            Text("No Outline")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 175)
                case .thumbnail:
                    PDFKitThumbnailView(pdfView: $pdfView, thumbnailWidth: 100)
                        .frame(width: 150)
                }
            }
            
            // MARK: - 阅读器
            PDFKitView(pdf: pdf, pdfView: $pdfView)
                .searchable(text: $findText, isPresented: $searchBarPresented, prompt: Text("Find in PDF"))
                .onChange(of: findText, performFind)
                .onReceive(NotificationCenter.default.publisher(for: .PDFViewPageChanged)) { _ in
                    currentPage = pdfView.currentPage?.label
                }
                .onReceive(NotificationCenter.default.publisher(for: .PDFViewAnnotationHit)) { userInfo in
                    print(userInfo)
                }
        }
        .animation(.easeInOut, value: tocContent)
        .navigationSubtitle("Page: \(currentPage ?? "Unknown")/\(pdf.pageCount)")
        // MARK: - 工具栏
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Menu {
                    Picker("Table of Contents", selection: $tocContent) {
                        ForEach(TOCContentType.allCases) { type in
                            Text(LocalizedStringKey(type.rawValue)).tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    Label("Table of Contents", systemImage: "sidebar.squares.left")
                }
            }
            if searchBarPresented {
                ToolbarItem {
                    Menu("Find Options", systemImage: "doc.text.magnifyingglass") {
                        Toggle("Case Sensitive", systemImage: "textformat", isOn: $caseSensitive)
                    }
                    .onChange(of: findOptions, performFind)
                }
            }
            ToolbarItemGroup(placement: .principal) {
                ControlGroup {
                    Picker("Highlighter Color", selection: $annotationColor) {
                        ForEach(HighlighterColor.allCases) { color in
                            HStack {
                                Image(systemName: "largecircle.fill.circle")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Color(color.color))
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
        }
        .onAppear {
            appState.findInPDFHandler = findInPDFHandler(_:)
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
            if !findResult.isEmpty {
                pdfView.setCurrentSelection(findResult.first!, animate: true)
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
        guard let page = select?.first?.pages.first else { return }
        
        select?.forEach { selection in
            let bounds = selection.bounds(for: page)
            let highlight = PDFAnnotation(bounds: bounds,
                                          forType: type,
                                          withProperties: nil)
            highlight.color = annotationColor.color
            
            page.addAnnotation(highlight)
        }
    }
}

#Preview {
    PDFReader(pdf: PDFDocument(url: Bundle.main.url(forResource: "sample", withExtension: "pdf")!)!)
        .frame(width: 800)
        .environmentObject(AppState())
}
