//
//  ProjectDetail.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI
import SwiftUIFlow
import SwiftData

struct ProjectDetail: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @AppStorage(AppStorageKey.User.loggedIn.rawValue)
    private var loggedIn: Bool = false
    @SceneStorage(SceneStorageKey.Table.customizations.rawValue)
    private var columnCustomization: TableColumnCustomization<Paper>

    @Bindable var project: Project
    @State private var selection = Set<Paper.ID>()
    @State private var sortOrder = [KeyPathComparator(\Paper.formattedCreateTime, order: .reverse)]
    @State private var updating = false
    @State private var progress: Progress?
    @State private var message: String?

    var body: some View {
        @Bindable var appState = appState

        Table(project.papers.sorted(using: sortOrder),
              selection: $selection,
              sortOrder: $sortOrder,
              columnCustomization: $columnCustomization
        ) {
            TableColumn("Status") { paper in
                (ModelStatus(rawValue: paper.status) ?? ModelStatus.normal).icon
                    .contentTransition(.symbolEffect(.replace))
            }
            .width(35)
            .alignment(.center)
            .customizationID("status")
            TableColumn("Title", value: \.title)
                .customizationID("title")
                .disabledCustomizationBehavior(.visibility)
            TableColumn("Authors", value: \.formattedAuthors)
                .customizationID("authors")
            TableColumn("Year") { paper in
                Text(paper.publicationYear ?? String(localized: "Unknown"))
            }
            .width(50)
            .customizationID("publicationYear")
            TableColumn("Publication") { paper in
                Text(paper.publication ?? String(localized: "Unknown"))
            }
            .customizationID("publication")
            TableColumn("Date Added", value: \.formattedCreateTime)
                .width(70)
                .customizationID("dateAdded")
            TableColumn("Tags") { paper in
                VFlow(alignment: .leading, spacing: 4) {
                    ForEach(paper.tags, id: \.self) { tag in
                        TagView(text: tag)
                    }
                }
                .clipped()
            }
            .customizationID("tags")
            TableColumn("Read") { paper in
                if paper.read {
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .width(35)
            .alignment(.center)
            .customizationID("read")
        }
        .contextMenu(forSelectionType: Paper.ID.self) { selectedPapers in
            if !selectedPapers.isEmpty {
                if selectedPapers.count == 1,
                   let paperId = selectedPapers.first,
                   let paper = project.papers.first(where: { $0.id == paperId }) {
                    Menu("Copy Information", systemImage: "doc.on.doc") {
                        ForEach(Paper.copiableProperties, id: \.0) { name, keypath in
                            Button(LocalizedStringKey(name)) {
                                if let value = paper[keyPath: keypath] as? String {
                                    setPasteboard(value)
                                }
                            }
                            .disabled(!(paper[keyPath: keypath] is String))
                        }
                    }
                }
                Divider()
                Button("Mark as Read", systemImage: "checkmark.circle.fill") {
                    Task {
                        for paper in await ModelService.shared.getPapers(id: selectedPapers) {
                            await ModelService.shared.setPaperRead(paper, read: true)
                        }
                    }
                }
                Button("Mark as Unread", systemImage: "circle") {
                    Task {
                        for paper in await ModelService.shared.getPapers(id: selectedPapers) {
                            await ModelService.shared.setPaperRead(paper, read: false)
                        }
                    }
                }
                Divider()
                Menu("Delete", systemImage: "trash") {
                    Button("Paper and PDF file", role: .destructive) {
                        handleDeletePaper(papers: selectedPapers, pdfOnly: false)
                    }
                    Button("PDF file only", role: .destructive) {
                        handleDeletePaper(papers: selectedPapers, pdfOnly: true)
                    }
                }
            }
        } primaryAction: { selectedPapers in
            let descriptor = FetchDescriptor(predicate: #Predicate<Paper> { selectedPapers.contains($0.id) })
            try? modelContext.fetchIdentifiers(descriptor).forEach { id in
                openWindow(id: AppWindow.reader.id, value: id)
            }
        }
        .overlay(alignment: .bottom) {
            if updating || message != nil {
                HStack(spacing: 8) {
                    if updating {
                        if let progress = progress {
                            ProgressView(value: progress.fractionCompleted)
                        } else {
                            ProgressView().controlSize(.small)
                        }
                        Text("Updating...")
                            .foregroundStyle(.secondary)
                    } else if let message = message {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
                .transition(.move(edge: .bottom))
            }
        }
        .task(id: project.id) {
            await updatePaperList()
        }
        .navigationTitle($project.name)
#if os(macOS)
        .navigationSubtitle(project.desc)
#endif
        .toolbar {
            ToolbarItemGroup {
                Spacer()
                Button("Share", systemImage: "square.and.arrow.up") {
                    appState.isSharingProject.toggle()
                }
                .disabled(!loggedIn)
                .popover(isPresented: $appState.isSharingProject, arrowEdge: .bottom) {
                    ShareProjectView(project: project)
                }

                Button("Project Settings", systemImage: "folder.badge.gear") {
                    appState.isEditingProject.toggle()
                }
                .sheet(isPresented: $appState.isEditingProject) {
                    ProjectCreateEditView(edit: true, project: project)
                }

                if project.remoteId != nil {
                    Button("Update", systemImage: "arrow.triangle.2.circlepath") {
                        Task {
                            await updatePaperList()
                        }
                    }
                }

                Button("Add Paper", systemImage: "plus") {
                    appState.isAddingPaper.toggle()
                }
                .sheet(isPresented: $appState.isAddingPaper) {
                    AddPaperView(project: project)
                }
            }
#if !os(macOS)
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
#endif
        }
    }

    func updatePaperList() async {
        guard let projectId = project.remoteId else { return }
        withAnimation {
            updating = true
        }
        do {
            let papers = try await API.shared.paper.listPaper(.with {
                $0.projectID = projectId
            }).papers
            let oldIdSet = Set(project.papers.map { $0.remoteId })
            for paperRemoteId in oldIdSet.subtracting(papers.map { $0.id }) {
                if let paperRemoteId = paperRemoteId,
                   let paper = await ModelService.shared.getPaper(remoteId: paperRemoteId) {
                    try await ModelService.shared.deletePaper(paper, localOnly: true)
                }
            }
            for paper in papers {
                if let localPaper = await ModelService.shared.getPaper(remoteId: paper.id) {
                    await ModelService.shared.updatePaper(localPaper, with: paper)
                } else {
                    let newPaper = await Paper(from: paper)
                    project.papers.append(newPaper)
                }
            }
            for paper in project.papers {
                if paper.status == ModelStatus.waitingForUpload.rawValue {
                    try await ModelService.shared.uploadPaper(paper, to: project)
                }
            }
            message = nil
        } catch {
            message = String(localized: "Failed to update: \(error.localizedDescription)")
        }
        withAnimation {
            updating = false
        }
    }

    func handleDeletePaper(papers: Set<Paper.ID>, pdfOnly: Bool) {
        withAnimation {
            updating = true
        }
        if papers.count > 1 {
            progress = Progress(totalUnitCount: Int64(papers.count))
        }
        Task {
            do {
                for paper in await ModelService.shared.getPapers(id: papers) {
                    try await ModelService.shared.deletePaper(paper, pdfOnly: pdfOnly)
                    progress?.completedUnitCount += 1
                }
                message = nil
            } catch {
                message = String(localized: "Failed to delete: \(error.localizedDescription)")
            }
            withAnimation {
                updating = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                progress = nil
            }
        }
    }
}

#Preview {
    ProjectDetail(project: ModelData.project1)
        .modelContainer(previewContainer)
#if os(macOS)
        .frame(width: 800, height: 600)
#endif
}
