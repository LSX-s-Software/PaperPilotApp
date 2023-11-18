//
//  FindResultRow.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/11/18.
//

import SwiftUI

struct FindResultRow: View {
    @Environment(FindViewModel<PDFFindResult>.self) private var findVM

    var selection: PDFFindResult.Selection
    @State private var attributedString: AttributedString?

    var body: some View {
        Group {
            if let attributedString = attributedString {
                Text(attributedString)
            } else {
                Text(selection.string)
                    .task {
                        attributedString = await attributedString(for: selection)
                    }
            }
        }
        .lineLimit(3)
        .multilineTextAlignment(.leading)
        .padding(.bottom, 4)
    }

    func attributedString(for selection: PDFFindResult.Selection) async -> AttributedString {
        var attributedString = AttributedString(selection.string)
        if let range = attributedString.range(of: findVM.findText, options: findVM.findOptions) {
            attributedString[range].inlinePresentationIntent = .stronglyEmphasized
            attributedString[range].foregroundColor = .yellow
        }
        return attributedString
    }
}
