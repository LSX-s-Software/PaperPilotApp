//
//  FindResultView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/28.
//

import SwiftUI
import PDFKit

struct FindResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PDFViewModel.self) private var pdfVM: PDFViewModel
    @Bindable var findVM: FindViewModel<PDFFindResult>

    @State private var currentSelection: PDFSelection?

    var body: some View {
        List(findVM.findResult, id: \.page, selection: $currentSelection) { result in
            Section("Page \(result.page.label ?? "")") {
                ForEach(result.selections) { selection in
                    FindResultRow(selection: selection)
                        .id(selection.id)
                        .tag(selection.id)
                }
            }
            .id(result.page)
        }
        .environment(findVM)
        .onChange(of: currentSelection) {
            if let selection = currentSelection {
#if os(iOS)
                dismiss()
#endif
                pdfVM.pdfView.go(to: selection)
                pdfVM.pdfView.setCurrentSelection(selection, animate: true)
            }
        }
        .overlay {
            if findVM.findText.isEmpty {
                ContentUnavailableView("Enter Text to Search", systemImage: "magnifyingglass")
            } else if findVM.finding && findVM.findResult.isEmpty {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Finding...")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else if findVM.findResult.isEmpty {
                ContentUnavailableView.search(text: findVM.findText)
            }
        }
    }
}
