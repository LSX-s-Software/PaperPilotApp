//
//  FindViewModel.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/27.
//

import SwiftUI

class FindViewModel<T>: ObservableObject {
    @Published var findText = ""
    @Published var searchBarPresented = false
    @Published var finding = false
    @Published var findResult = [T]()
    @Published var caseSensitive = false
    @Published var currentSelectionIndex = 0
    var findOptions: NSString.CompareOptions {
        var options: NSString.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        if caseSensitive {
            options.remove(.caseInsensitive)
        }
        return options
    }

    func focusSearchBar() {
        searchBarPresented = true
    }

    func reset() {
        searchBarPresented = false
        findText = ""
        finding = false
        findResult.removeAll()
        currentSelectionIndex = 0
    }
}
