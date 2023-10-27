//
//  AppState.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/20.
//

import SwiftUI

struct SelectedPaperKey: FocusedValueKey {
    typealias Value = Binding<Paper>
}

extension FocusedValues {
    var selectedPaper: SelectedPaperKey.Value? {
        get { self[SelectedPaperKey.self] }
        set { self[SelectedPaperKey.self] = newValue }
    }
}

@Observable class AppState {
    var findingPaper: Set<Paper.ID> = []

    var isShowingJoinProjectView = false
    var incomingURL: URL?

    var isCreatingProject = false
    var isEditingProject = false
    var isAddingPaper = false
    var isSharingProject = false

    func handleIncomingURL(url: URL) {
        incomingURL = url
        guard url.scheme == AppURLScheme.scheme else { return }

        switch url.host() {
        case .some(AppURLScheme.Hosts.project.rawValue):
            isShowingJoinProjectView = true
        case .none:
            break
        default:
            print("Unknown URL: \(url.absoluteString)")
        }
    }
}
