//
//  TranslatorView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/20.
//

import SwiftUI
import Throttler

struct TranslatorView: View {
    @ObservedObject var viewModel: TranslatorViewModel

    var body: some View {
        Form {
            DisclosureGroup(isExpanded: .constant(viewModel.translateBySelection)) {
                Toggle("Trim line breaks", isOn: $viewModel.trimNewlines)
            } label: {
                Toggle("Translate by selection", isOn: $viewModel.translateBySelection)
            }

            Section("Original Text") {
                Picker("Language", selection: $viewModel.sourceLanguage) {
                    ForEach(TranslatorLang.allCases) { lang in
                        Text(lang.localizedStringKey).tag(lang)
                    }
                }
                .onChange(of: viewModel.sourceLanguage) {
                    Task { await viewModel.translate() }
                }

                TextEditor(text: $viewModel.originalText)
                    .font(.body)
                    .frame(maxHeight: 500)
                    .fixedSize(horizontal: false, vertical: true)
                    .scrollContentBackground(.hidden)
                    .onChange(of: viewModel.originalText) {
                        Task { await viewModel.translate() }
                    }
            }

            Section("Translated Text") {
                Picker("Language", selection: $viewModel.targetLanguage) {
                    ForEach(TranslatorLang.allCases.filter({ !$0.isAuto && $0 != viewModel.sourceLanguage })) { lang in
                        Text(lang.localizedStringKey).tag(lang)
                    }
                }
                .onChange(of: viewModel.targetLanguage) {
                    Task { await viewModel.translate() }
                }

                if let error = viewModel.errorMsg {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(error)
                    }
                    .foregroundColor(.red)
                } else {
                    TextEditor(text: $viewModel.translatedText)
                        .font(.body)
                        .frame(maxHeight: 500)
                        .fixedSize(horizontal: false, vertical: true)
                        .scrollContentBackground(.hidden)
                }
            }

            Section {
                AsyncButton("Translate", disabled: viewModel.originalText.isEmpty, action: viewModel.translate)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    TranslatorView(viewModel: TranslatorViewModel())
        .frame(width: 300)
}
