//
//  PDFError.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/11/17.
//

import Foundation

enum PDFError: Error, LocalizedError {
    case noAccess
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .noAccess: String(localized: "You don't have access to the PDF.")
        case .writeFailed: String(localized: "Failed to write PDF.")
        }
    }
}
