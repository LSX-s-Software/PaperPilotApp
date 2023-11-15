//
//  AppState.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/20.
//

import SwiftUI
import OSLog
import CoreSpotlight

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
    static let logger = LoggerFactory.make(category: "AppState")

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
            Self.logger.warning("Unknown URL: \(url.absoluteString)")
        }
    }

    func handleSpotlight(userActivity: NSUserActivity) {
        guard let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            Self.logger.warning("No unique identifier found in user activity")
            return
        }
        if uniqueIdentifier.hasPrefix(SpotlightHelper.IdentifierPrefix.project.rawValue) {
            let projectIdString = String(uniqueIdentifier.dropFirst(SpotlightHelper.IdentifierPrefix.project.rawValue.count + 1))
            if let projectId = UUID(uuidString: projectIdString) {
                NotificationCenter.default.post(name: .selectProject, object: projectId)
            }
        } else if uniqueIdentifier.hasPrefix(SpotlightHelper.IdentifierPrefix.paper.rawValue) {
            let paperIdString = String(uniqueIdentifier.dropFirst(SpotlightHelper.IdentifierPrefix.paper.rawValue.count + 1))
            if let paperId = UUID(uuidString: paperIdString) {
                NotificationCenter.default.post(name: .selectPaper, object: paperId)
            }
        } else {
            Self.logger.warning("Unknown unique identifier: \(uniqueIdentifier)")
        }
    }
}

extension NSNotification.Name {
    static let selectProject = NSNotification.Name("selectProject")
    static let selectPaper = NSNotification.Name("selectPaper")
}
