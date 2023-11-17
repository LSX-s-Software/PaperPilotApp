//
//  FindViewModel.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/27.
//

import SwiftUI

@Observable class FindViewModel<T> {
    var findText = ""
    var searchBarFocused = false
    var isShowingFindSheet = false
    var finding = false
    var findResult = [T]()
    var caseSensitive = false
    var currentSelectionIndex = 0
    var findOptions: NSString.CompareOptions {
        var options: NSString.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        if caseSensitive {
            options.remove(.caseInsensitive)
        }
        return options
    }

    func reset() {
        findText = ""
        finding = false
        findResult.removeAll()
        currentSelectionIndex = 0
    }
}
