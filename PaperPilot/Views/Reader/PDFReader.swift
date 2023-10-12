//
//  PDFReader.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/11.
//

import SwiftUI
import PDFKit

struct PDFReader: View {
    @EnvironmentObject var appState: AppState
    
    let pdf: PDFDocument
    
    enum TOCContentType: String, Identifiable, CaseIterable {
        case none = "Hide TOC"
        case outline = "Outline"
        case thumbnail = "Thumbnail"
        
        var id: Self { self }
    }
    @State private var tocContent: TOCContentType = .outline
    
    @State private var pdfView = PDFView()
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
                .onChange(of: findText) {
                    performFind()
                }
        }
        .animation(.easeInOut, value: tocContent)
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
                ToolbarItemGroup {
                    Menu("Find Options", systemImage: "doc.text.magnifyingglass") {
                        Toggle("Case Sensitive", systemImage: "textformat", isOn: $caseSensitive)
                    }
                    .onChange(of: findOptions) {
                        performFind()
                    }
                }
            }
        }
        .onAppear {
            appState.findInPDFHandler = findInPDFHandler(_:)
        }
    }
    
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
    
    func performFind() {
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
    
    func findResultText(for selection: PDFSelection) -> AttributedString {
        guard let extendSelection = selection.copy() as? PDFSelection else { return "" }
        extendSelection.extendForLineBoundaries()
        var attributedString = AttributedString(extendSelection.string ?? "")
        guard let range = attributedString.range(of: selection.string ?? "", options: findOptions) else { return "" }
        attributedString[range].inlinePresentationIntent = .stronglyEmphasized
        attributedString[range].foregroundColor = .yellow
        return attributedString
    }
}

#Preview {
    PDFReader(pdf: PDFDocument(url: Bundle.main.url(forResource: "sample", withExtension: "pdf")!)!)
}
