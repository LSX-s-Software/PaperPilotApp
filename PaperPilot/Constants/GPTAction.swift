//
//  GPTAction.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/11/11.
//

import Foundation

enum GPTAction: String, CaseIterable, Identifiable, CustomStringConvertible, CustomLocalizedStringResourceConvertible {
    case summarize
    case rewrite
    case translate
    case explain

    var id: Self { self }

    var description: String {
        switch self {
        case .summarize: String(localized: "Summarize selected text")
        case .rewrite: String(localized: "Rewrite selected text")
        case .translate: String(localized: "Translate selected text")
        case .explain: String(localized: "Explain selected text")
        }
    }

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .summarize: "Summarize"
        case .rewrite: "Rewrite"
        case .translate: "Translate"
        case .explain: "Explain"
        }
    }
}

enum GPTError: Error, LocalizedError {
    case unknown(Int)
    /// 生成长度达到最大值
    case lengthLimitExceeded
    /// 生成内容被过滤
    case contentFiltered

    var errorDescription: String? {
        switch self {
        case .unknown(let code): return String(localized: "Unknown error: \(code)")
        case .lengthLimitExceeded: return String(localized: "The generated content exceeds the maximum length.")
        case .contentFiltered: return String(localized: "The generated content is filtered.")
        }
    }

    init?(reason: Ai_FinishReason) {
        switch reason {
        case .UNRECOGNIZED(let code): self = .unknown(code)
        case .length: self = .lengthLimitExceeded
        case .contentFilter: self = .contentFiltered
        default: return nil
        }
    }
}
