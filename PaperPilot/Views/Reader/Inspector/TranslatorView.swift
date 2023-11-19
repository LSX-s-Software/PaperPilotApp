//
//  TranslatorView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/20.
//

import SwiftUI
import GRPC
import Throttler

struct TranslatorView: View {
    @Environment(PDFViewModel.self) private var pdfVM: PDFViewModel

    @AppStorage(AppStorageKey.User.loggedIn.rawValue)
    private var loggedIn = false

    @State private var originalText = ""
    @State private var translatedText = ""
    @State private var sourceLanguage = TranslatorLang.auto
    @State private var targetLanguage = TranslatorLang.chinese
    @State private var translateBySelection = true
    @State private var trimNewlines = true
    @State private var errorMsg: String?

    var body: some View {
        Form {
            DisclosureGroup(isExpanded: .constant(translateBySelection)) {
                Toggle("Trim line breaks", isOn: $trimNewlines)
            } label: {
                Toggle("Translate by selection", isOn: $translateBySelection)
            }

            Section("Original Text") {
                Picker("Language", selection: $sourceLanguage) {
                    ForEach(TranslatorLang.allCases) { lang in
                        Text(lang.localizedStringKey).tag(lang)
                    }
                }
                .onChange(of: sourceLanguage) {
                    Task { await translate() }
                }

                TextEditor(text: $originalText)
                    .font(.body)
                    .frame(maxHeight: 500)
                    .fixedSize(horizontal: false, vertical: true)
                    .scrollContentBackground(.hidden)
                    .overlay(alignment: .topLeading) {
                        if originalText.isEmpty {
                            Text("Enter to translate")
                                .foregroundStyle(.placeholder)
                                .offset(x: 8)
                                .allowsHitTesting(false)
                        }
                    }
                    .onChange(of: originalText) {
                        throttle(option: .ensureLast) {
                            Task { await translate() }
                        }
                    }
                    .onReceive(
                        NotificationCenter.default.publisher(for: .PDFViewSelectionChanged)
                            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
                    ) { _ in
                        if translateBySelection,
                           let selection = pdfVM.pdfView.currentSelection?.string {
                            originalText = trimNewlines
                            ? selection.trimmingCharacters(in: .newlines)
                            : selection
                        }
                    }
            }

            Section("Translated Text") {
                Picker("Language", selection: $targetLanguage) {
                    ForEach(TranslatorLang.allCases.filter({ !$0.isAuto && $0 != sourceLanguage })) { lang in
                        Text(lang.localizedStringKey).tag(lang)
                    }
                }
                .onChange(of: targetLanguage) {
                    Task { await translate() }
                }

                if let error = errorMsg {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(error)
                    }
                    .foregroundColor(.red)
                } else {
                    ScrollView {
                        Text(translatedText)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 500)
                }
            }

            Section {
                AsyncButton("Translate", action: translate)
                    .disabled(originalText.isEmpty || !loggedIn)
            }
        }
        .formStyle(.grouped)
    }

    func translate() async {
        guard loggedIn else { return }
        do {
            let result = try await API.shared.translation.translate(.with {
                $0.content = originalText
                $0.sourceLanguage = sourceLanguage.rawValue
                $0.targetLanguage = targetLanguage.rawValue
            }).result
            translatedText = result
            errorMsg = nil
        } catch let error as GRPCStatus {
            errorMsg = error.message
        } catch {
            errorMsg = error.localizedDescription
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

#Preview {
    TranslatorView()
        .environment(PDFViewModel())
        .frame(width: 300)
}
