//
//  PaperInfo.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/27.
//

import SwiftUI
import SwiftUIFlow

private struct EditingKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var editing: Bool {
        get { self[EditingKey.self] }
        set { self[EditingKey.self] = newValue }
    }
}

struct EditToggleButton: View {
    @Binding var editing: Bool
    var saving: Bool

    var onSubmit: () -> Void
    var onCancel: (() -> Void)?

    var body: some View {
        Group {
            if editing {
                if saving {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 2)
                }
                ControlGroup {
                    Button("Save", systemImage: "checkmark", action: onSubmit)
                    Button("Cancel", systemImage: "xmark") {
                        onCancel?()
                        editing = false
                    }
                }
                .fixedSize()
                .disabled(saving)
            } else {
                Button("Edit", systemImage: "pencil") {
                    editing = true
                }
            }
        }
        .labelStyle(.iconOnly)
        .controlSize(.small)
    }
}

private struct InfoRow: View {
    @Environment(\.editing) var editing

    let title: LocalizedStringKey
    @Binding var value: String

    var body: some View {
        LabeledContent(title) {
            Group {
                if editing {
                    TextField(title, text: $value)
                } else {
                    Text(value)
                }
            }
            .multilineTextAlignment(.trailing)
        }
    }
}

struct PaperInfo: View {
    @Bindable var paper: Paper
    @State private var editing = false
    @State private var saving = false
    @State private var hasError = false
    @State private var errorMsg: String?

    @State private var doi: String
    @State private var publication: String
    @State private var publicationYear: String
    @State private var event: String
    @State private var volume: String
    @State private var issue: String
    @State private var pages: String
    @State private var url: String
    @State private var abstract: String

    init(paper: Paper) {
        self.paper = paper
        self._doi = State(initialValue: paper.doi ?? "")
        self._publication = State(initialValue: paper.publication ?? "")
        self._publicationYear = State(initialValue: paper.publicationYear ?? "")
        self._event = State(initialValue: paper.event ?? "")
        self._volume = State(initialValue: paper.volume ?? "")
        self._issue = State(initialValue: paper.issue ?? "")
        self._pages = State(initialValue: paper.pages ?? "")
        self._url = State(initialValue: paper.url ?? "")
        self._abstract = State(initialValue: paper.abstract ?? "")
    }

    var body: some View {
        List {
            Section("Tags") {
                VFlow(alignment: .leading, spacing: 4) {
                    ForEach(Array(paper.tags.enumerated()), id: \.offset) { index, tag in
                        TagView(text: tag) { newValue in
                            var newTags = paper.tags
                            newTags[index] = newValue
                            modify(newTags: newTags)
                        } onDelete: {
                            var newTags = paper.tags
                            newTags.remove(at: index)
                            modify(newTags: newTags)
                        }
                    }
                    AddTagView { newTag in
                        var newTags = paper.tags
                        newTags.append(newTag)
                        modify(newTags: newTags)
                    }
                }
            }
            .listRowSeparator(.hidden)
            
            Section {
                InfoRow(title: "DOI", value: $doi)
                InfoRow(title: "Publication", value: $publication)
                InfoRow(title: "Publication Year", value: $publicationYear)
                InfoRow(title: "Event", value: $event)
                InfoRow(title: "Volume", value: $volume)
                InfoRow(title: "Issue", value: $issue)
                InfoRow(title: "Pages", value: $pages)
                InfoRow(title: "URL", value: $url)
                HStack {
                    Text("Date Added")
                    Spacer()
                    Text(paper.formattedCreateTime)
                        .foregroundStyle(.secondary)
                }
            } header: {
                HStack {
                    Text("Basic Info")
                    Spacer()
                    EditToggleButton(editing: $editing, saving: saving, onSubmit: submit, onCancel: reset)
                }
            }
            .environment(\.editing, editing)

            Section("Keywords") {
                VFlow(alignment: .leading, spacing: 4) {
                    ForEach(Array(paper.keywords.enumerated()), id: \.offset) { index, keyword in
                        TagView(text: keyword) { newValue in
                            var newKeywords = paper.keywords
                            newKeywords[index] = newValue
                            modify(newKeywords: newKeywords)
                        } onDelete: {
                            var newKeywords = paper.keywords
                            newKeywords.remove(at: index)
                            modify(newKeywords: newKeywords)
                        }
                    }
                    AddTagView { newKeyword in
                        var newKeywords = paper.keywords
                        newKeywords.append(newKeyword)
                        modify(newKeywords: newKeywords)
                    }
                }
            }
            .listRowSeparator(.hidden)
            
            Section {
                TextEditor(text: $abstract)
                    .font(.body)
                    .disabled(!editing)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 150)
                    .overlay(alignment: .topLeading) {
                        if abstract.isEmpty {
                            Text("No Abstract")
                                .foregroundStyle(.placeholder)
                                .offset(x: 8)
                                .allowsHitTesting(false)
                        }
                    }
            } header: {
                HStack {
                    Text("Abstract")
                    Spacer()
                    EditToggleButton(editing: $editing, saving: saving, onSubmit: submit, onCancel: reset)
                }
            }
        }
        .alert("Failed to update paper info", isPresented: $hasError) {} message: {
            if let errorMsg = errorMsg {
                Text(errorMsg)
            }
        }

#if os(iOS)
        .listStyle(.insetGrouped)
#endif
    }
}

extension PaperInfo {
    func reset() {
        doi = paper.doi ?? ""
        publication = paper.publication ?? ""
        publicationYear = paper.publicationYear ?? ""
        event = paper.event ?? ""
        volume = paper.volume ?? ""
        issue = paper.issue ?? ""
        pages = paper.pages ?? ""
        url = paper.url ?? ""
        abstract = paper.abstract ?? ""
    }

    func submit() {
        saving = true
        Task {
            do {
                try await ModelService.shared.updatePaper(paper,
                                                          abstract: abstract,
                                                          publicationYear: publicationYear,
                                                          publication: publication,
                                                          event: event,
                                                          volume: volume,
                                                          issue: issue,
                                                          pages: pages,
                                                          url: url,
                                                          doi: doi)
                editing = false
            } catch {
                errorMsg = error.localizedDescription
                hasError = true
            }
            saving = false
        }
    }

    func modify(newTags: [String]? = nil, newKeywords: [String]? = nil) {
        if newTags == nil && newKeywords == nil { return }
        Task {
            do {
                try await ModelService.shared.updatePaper(paper, keywords: newKeywords, tags: newTags)
            } catch {
                errorMsg = error.localizedDescription
                hasError = true
            }
        }
    }
}

#Preview {
    PaperInfo(paper: ModelData.paper1)
        .frame(width: 300)
}
