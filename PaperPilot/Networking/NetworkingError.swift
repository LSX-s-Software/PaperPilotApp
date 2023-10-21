//
//  NetworkingError.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/17.
//

import Foundation

enum NetworkingError: Error {
    case invalidURL
    case responseFormatError
    case networkError(Error)
    case notFound
    case requestError(code: Int, message: String)
}

extension NetworkingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "Invalid URL")
        case .responseFormatError:
            return String(localized: "Response format error")
        case .networkError(let error):
            return error.localizedDescription
        case .notFound:
            return String(localized: "Not found")
        case .requestError(let code, let message):
            return "\(message)(\(code))"
        }
    }
}
