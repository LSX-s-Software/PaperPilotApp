//
//  TranslatorLang.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/21.
//

import SwiftUI

enum TranslatorLang: String, CaseIterable, Identifiable {
    case auto = "auto"
    case english = "en"
    case chinese = "zh"
    case japanese = "ja"
    case korean = "ko"
    case french = "fr"
    case german = "de"
    case spanish = "es"
    case italian = "it"
    case russian = "ru"
    case portuguese = "pt"
    case arabic = "ar"

    var id: String { self.rawValue }

    var isAuto: Bool { self == .auto }

    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .auto:
            return "Auto Detect"
        case .english:
            return "English"
        case .chinese:
            return "Chinese"
        case .japanese:
            return "Japanese"
        case .korean:
            return "Korean"
        case .french:
            return "French"
        case .german:
            return "German"
        case .spanish:
            return "Spanish"
        case .italian:
            return "Italian"
        case .russian:
            return "Russian"
        case .portuguese:    
            return "Portuguese"
        case .arabic:
            return "Arabic"
        }
    }
}
