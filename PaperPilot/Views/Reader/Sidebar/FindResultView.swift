//
//  FindResultView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/28.
//

import SwiftUI
import PDFKit

struct FindResultView: View {
    @EnvironmentObject var pdfVM: PDFViewModel
    @ObservedObject var findVM: FindViewModel<PDFSelection>

    @State private var currentSelection: PDFSelection?

    var body: some View {
        List(findVM.findResult, id: \.self, selection: Binding { currentSelection } set: { selection in
            if let page = selection?.pages.first {
                pdfVM.pdfView.go(to: page)
            }
            pdfVM.pdfView.setCurrentSelection(selection, animate: true)
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
        .animation(.easeInOut, value: findVM.finding)
        .onChange(of: findVM.currentSelectionIndex) {
            currentSelection = findVM.findResult[findVM.currentSelectionIndex]
        }
        .overlay {
            if findVM.finding {
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
                ContentUnavailableView.search
            }
        }
    }

    func findResultText(for selection: PDFSelection) -> AttributedString {
        guard let extendSelection = selection.copy() as? PDFSelection else { return "" }
        extendSelection.extendForLineBoundaries()
        var attributedString = AttributedString(extendSelection.string ?? "")
        guard let range = attributedString.range(of: selection.string ?? "", options: findVM.findOptions) else { return "" }
        attributedString[range].inlinePresentationIntent = .stronglyEmphasized
        attributedString[range].foregroundColor = .yellow
        return attributedString
    }
}
