//
//  AppState.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/20.
//

import Foundation

class AppState: ObservableObject {
    @Published var findingInPDF = false
    var findInPDFHandler: ((Bool) -> Void)?

    @Published var isShowingJoinProjectView = false
    @Published var incomingURL: URL?

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
