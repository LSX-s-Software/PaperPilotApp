//
//  TranslatorView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/20.
//

import SwiftUI
import Throttler

struct TranslatorView: View {
    @EnvironmentObject private var pdfVM: PDFViewModel
    @Environment(TranslatorViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

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
                    .overlay(alignment: .topLeading) {
                        if viewModel.originalText.isEmpty {
                            Text("Enter to translate")
                                .foregroundStyle(.placeholder)
                                .offset(x: 8)
                                .allowsHitTesting(false)
                        }
                    }
                    .onChange(of: viewModel.originalText) {
                        throttle(option: .ensureLast) {
                            Task { await viewModel.translate() }
                        }
                    }
                    .onReceive(
                        NotificationCenter.default.publisher(for: .PDFViewSelectionChanged)
                            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
                    ) { _ in
                        if viewModel.translateBySelection,
                           let selection = pdfVM.pdfView.currentSelection?.string {
                            viewModel.originalText = viewModel.trimNewlines
                            ? selection.trimmingCharacters(in: .newlines)
                            : selection
                        }
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
                    ScrollView {
                        Text(viewModel.translatedText)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 500)
                }
            }

            Section {
                AsyncButton("Translate", action: viewModel.translate)
                    .disabled(viewModel.originalText.isEmpty)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    TranslatorView()
        .environmentObject(PDFViewModel())
        .environment(TranslatorViewModel())
        .frame(width: 300)
}
