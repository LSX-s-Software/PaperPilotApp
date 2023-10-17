//
//  NetworkingError.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/17.
//

import Foundation

enum NetworkingError: Error {
    case invalidURL
    case networkError(Error)
    case notFound
    case dataFormatError
}

extension NetworkingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "Invalid URL")
        case .networkError(let error):
            return error.localizedDescription
        case .notFound:
            return String(localized: "Not found")
        case .dataFormatError:
            return String(localized: "Data format error")
        }
    }
}
