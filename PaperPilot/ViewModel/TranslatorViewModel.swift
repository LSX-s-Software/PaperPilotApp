//
//  TranslatorViewModel.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/20.
//

import SwiftUI
import GRPC

class TranslatorViewModel: ObservableObject {
    @Published var originalText = ""
    @Published var translatedText = ""
    @Published var sourceLanguage = TranslatorLang.auto
    @Published var targetLanguage = TranslatorLang.chinese
    @Published var translateBySelection = true
    @Published var trimNewlines = true
    @Published var errorMsg: String?

    func translate() async {
        do {
            let result = try await API.shared.translation.translate(.with {
                $0.content = originalText
                $0.sourceLanguage = sourceLanguage.rawValue
                $0.targetLanguage = targetLanguage.rawValue
            }).result
            DispatchQueue.main.async { [weak self] in
                self?.translatedText = result
                self?.errorMsg = nil
            }
        } catch let error as GRPCStatus {
            DispatchQueue.main.async { [weak self] in
                self?.errorMsg = error.message
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMsg = error.localizedDescription
            }
        }
    }

    func swapLanguage() {
        if sourceLanguage.isAuto {
            sourceLanguage = targetLanguage
            targetLanguage = targetLanguage == .english ? .chinese : .english
        } else {
            swap(&sourceLanguage, &targetLanguage)
        }
    }
}
