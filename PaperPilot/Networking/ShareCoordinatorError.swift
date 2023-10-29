//
//  ShareCoordinatorError.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/27.
//

import Foundation

enum ShareCoordinatorError: Error {
    case notConnected
}

extension ShareCoordinatorError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return String(localized: "ShareDB service is not connected.")
        }
    }
}
