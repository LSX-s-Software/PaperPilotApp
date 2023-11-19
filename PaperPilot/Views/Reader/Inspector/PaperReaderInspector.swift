//
//  PaperReaderInspector.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/27.
//

import SwiftUI

private enum InspectorContent: String, Identifiable, CaseIterable {
    case info
    case note
    case translator
    case ai

    var id: Self { self }
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .info: "Info"
        case .note: "Note"
        case .translator: "Translator"
        case .ai: "AI"
        }
    }
}

struct PaperReaderInspector: View {
    @Bindable var paper: Paper

    @AppStorage(AppStorageKey.Reader.inspectorContent.rawValue)
    private var inspectorContent = InspectorContent.info
    @AppStorage(AppStorageKey.Reader.isShowingInspector.rawValue)
    private var isShowingInspector = true
    @AppStorage(AppStorageKey.User.loggedIn.rawValue)
    private var loggedIn = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Picker("Sidebar Content", selection: $inspectorContent) {
                ForEach(InspectorContent.allCases) { content in
                    Text(content.localizedStringKey).tag(content)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding()

            Group {
                switch inspectorContent {
                case .info:
                    PaperInfo(paper: paper)
                case .note:
                    SharedNoteView(paper: paper)
                case .translator:
                    TranslatorView()
                case .ai:
                    GPTView()
                }
            }
            .overlay {
                if !loggedIn && (inspectorContent == .translator || inspectorContent == .ai) {
                    LoginPromptView()
                }
            }
        }
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                Button("Toggle Inspector", systemImage: "sidebar.right") {
                    isShowingInspector.toggle()
                }
            }
#elseif os(macOS)
            Spacer()
            Button("Toggle Inspector", systemImage: "sidebar.right") {
                isShowingInspector.toggle()
            }
#endif
        }
    }
}

#Preview {
    PaperReaderInspector(paper: ModelData.paper1)
        .environment(PDFViewModel())
        .frame(width: 300, height: 500)
}
