//
//  FindViewModel.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/27.
//

import SwiftUI
import PDFKit
import Combine

@Observable class FindViewModel<T> {
    var findText = ""
    var searchBarFocused = false
    var isShowingFindSheet = false
    var finding = false
    var findResult = [T]()
    var caseSensitive = false
    var currentSelectionIndex = 0
    var findSubscription: AnyCancellable?
    var findOptions: NSString.CompareOptions {
        var options: NSString.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        if caseSensitive {
            options.remove(.caseInsensitive)
        }
        return options
    }

    func reset() {
        findSubscription = nil
        findText = ""
        finding = false
        findResult.removeAll()
        currentSelectionIndex = 0
    }
}

struct PDFFindResult {
    struct Selection: Identifiable {
        var id: PDFSelection { selection }

        var selection: PDFSelection
        var string: String
    }

    var selections: [Selection]
    var page: PDFPage
}
