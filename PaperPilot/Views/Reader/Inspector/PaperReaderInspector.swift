//
//  PaperReaderInspector.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/27.
//

import SwiftUI

private enum EditableContent {
    case none
    case title
    case author
}

private enum InspectorContent: String, Identifiable, CaseIterable {
    case info
    case note
    case translator

    var id: Self { self }
    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .info: "Info"
        case .note: "Note"
        case .translator: "Translator"
        }
    }
}

struct PaperReaderInspector: View {
    @Bindable var paper: Paper

    @AppStorage(AppStorageKey.Reader.inspectorContent.rawValue)
    private var inspectorContent = InspectorContent.info
    @AppStorage(AppStorageKey.Reader.isShowingInspector.rawValue)
    private var isShowingInspector = true

    @State private var isShowingEditButton = EditableContent.none
    @State private var editing = EditableContent.none
    @State private var newTitle = ""
    @State private var newAuthor = ""
    @State private var newAuthors = [String]()
    @State private var hasError = false
    @State private var errorMsg: String?

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Group {
                    Text(paper.title)
                        .font(.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(alignment: .trailing) {
                            if isShowingEditButton == .title {
                                Button("Edit", systemImage: "pencil") {
                                    newTitle = paper.title
                                    editing = .title
                                }
                                .labelStyle(.iconOnly)
                            }
                        }
                        .onHover { hover in
                            isShowingEditButton = hover ? .title : .none
                        }
                        .popover(
                            isPresented: Binding { editing == .title } set: { _ in editing = .none },
                            arrowEdge: .bottom
                        ) {
                            TextField("Enter title", text: $newTitle)
                                .padding()
                                .onSubmit {
                                    if !newTitle.isEmpty {
                                        handleModifyPaper(newTitle: newTitle)
                                    }
                                }
                        }

                    Text(paper.formattedAuthors)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(alignment: .trailing) {
                            if isShowingEditButton == .author {
                                Button("Edit", systemImage: "pencil") {
                                    newAuthors = paper.authors
                                    editing = .author
                                }
                                .labelStyle(.iconOnly)
                            }
                        }
                        .onHover { hover in
                            isShowingEditButton = hover ? .author : .none
                        }
                        .popover(
                            isPresented: Binding { editing == .author } set: { _ in editing = .none },
                            arrowEdge: .bottom
                        ) {
                            List {
                                ForEach(newAuthors, id: \.self) { author in
                                    Text(author)
                                }
                                .onMove { source, destination in
                                    newAuthors.move(fromOffsets: source, toOffset: destination)
                                    handleModifyPaper(newAuthors: newAuthors)
                                }
                                .onDelete {
                                    newAuthors.remove(atOffsets: $0)
                                    handleModifyPaper(newAuthors: newAuthors)
                                }
                                Section("Add author") {
                                    TextField("New author", text: $newAuthor)
                                    Button("Add") {
                                        if !newAuthor.isEmpty {
                                            newAuthors.append(newAuthor)
                                            newAuthor = ""
                                            handleModifyPaper(newAuthors: newAuthors)
                                        }
                                    }
                                    .keyboardShortcut(.defaultAction)
                                }
                            }
                        }
                }
                .multilineTextAlignment(.leading)

                Picker("Sidebar Content", selection: $inspectorContent) {
                    ForEach(InspectorContent.allCases) { content in
                        Text(content.localizedStringKey).tag(content)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .padding([.horizontal, .top])

            switch inspectorContent {
            case .info:
                PaperInfo(paper: paper)
            case .note:
                SharedNoteView(paper: paper)
            case .translator:
                TranslatorView()
            }
        }
        .inspectorColumnWidth(min: 250, ideal: 300)
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                Button("Show Inspector", systemImage: "sidebar.right") {
                    isShowingInspector.toggle()
                }
            }
#else
            Spacer()
            Button("Show Inspector", systemImage: "sidebar.right") {
                isShowingInspector.toggle()
            }
#endif
        }
        .alert("Failed to update paper info", isPresented: $hasError) { } message: {
            Text(errorMsg ?? String(localized: "Unknown error"))
        }
    }

    func handleModifyPaper(newTitle: String? = nil, newAuthors: [String]? = nil) {
        if newTitle == nil && newAuthors == nil { return }
        Task {
            do {
                try await ModelService.shared.updatePaper(paper, title: newTitle, authors: newAuthors)
                editing = .none
            } catch {
                hasError = true
                errorMsg = error.localizedDescription
            }
        }
    }
}

#Preview {
    PaperReaderInspector(paper: ModelData.paper1)
}
