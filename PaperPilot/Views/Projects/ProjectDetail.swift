//
//  ProjectDetail.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI
import SwiftUIFlow

struct ProjectDetail: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.modelContext) private var modelContext
    
    private let copiableProperties: [(String, PartialKeyPath)] = [("Title", \Paper.title),
                                                                  ("Abstract", \Paper.abstract),
                                                                  ("URL", \Paper.url),
                                                                  ("DOI", \Paper.doi)]
    
    @Bindable var project: Project
    @State private var selection = Set<Paper.ID>()
    @State private var sortOrder = [KeyPathComparator(\Paper.formattedCreateTime, order: .reverse)]
    @State private var isShowingEditProjectSheet = false
    @State private var isShowingAddPaperSheet = false
    @State private var isShowingSharePopover = false
    @AppStorage(AppStorageKey.User.username.rawValue)
    private var username: String?
    var shareURL: URL {
        let queryItems = [URLQueryItem(name: AppURLScheme.QueryKeys.Project.invitation.rawValue, value: project.invitationCode)]
        return AppURLScheme(host: .project, queryItems: queryItems).url
    }

    var onDelete: (() -> Void)?
    
    var body: some View {
        Table(project.papers.sorted(using: sortOrder), selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Title", value: \.title)
            TableColumn("Authors", value: \.formattedAuthors)
            TableColumn("Publication Year") { paper in
                Text(paper.publicationYear ?? "Unknown")
            }
            .width(50)
            TableColumn("Publication") { paper in
                Text(paper.publication ?? "Unknown")
            }
            TableColumn("Date Added", value: \.formattedCreateTime)
                .width(70)
            TableColumn("Tags") { paper in
                VFlow(alignment: .leading, spacing: 4) {
                    ForEach(paper.tags, id: \.self) { tag in
                        TagView(text: tag)
                    }
                }
                .clipped()
            }
            TableColumn("Read") { paper in
                if paper.read {
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .width(35)
        }
        .contextMenu(forSelectionType: Paper.ID.self) { selectedPapers in
            if !selectedPapers.isEmpty {
                if selectedPapers.count == 1,
                   let paperId = selectedPapers.first,
                   let paper = project.papers.first(where: { $0.id == paperId }) {
                    Menu("Copy Information", systemImage: "doc.on.doc") {
                        ForEach(copiableProperties, id: \.0) { name, keypath in
                            Button(LocalizedStringKey(name)) {
                                if let value = paper[keyPath: keypath] as? String {
                                    setPasteboard(value)
                                }
                            }
                        }
                    }
                }
                Divider()
                Button("Mark as Read", systemImage: "checkmark.circle.fill") {
                    for paperId in selectedPapers {
                        if let index = project.papers.firstIndex(where: { $0.id == paperId }) {
                            project.papers[index].read = true
                        }
                    }
                }
                Button("Mark as Unread", systemImage: "circle") {
                    for paperId in selectedPapers {
                        if let index = project.papers.firstIndex(where: { $0.id == paperId }) {
                            project.papers[index].read = false
                        }
                    }
                }
                Divider()
                Menu("Delete", systemImage: "trash") {
                    Button("Paper and PDF file", role: .destructive) {
                        handleDeletePaper(papers: selectedPapers, paper: true, pdf: true)
                    }
                    Button("Paper only", role: .destructive) {
                        handleDeletePaper(papers: selectedPapers, paper: true, pdf: false)
                    }
                    Button("PDF file only", role: .destructive) {
                        handleDeletePaper(papers: selectedPapers, paper: false, pdf: true)
                    }
                }
            }
        } primaryAction: { selectedPapers in
            if selectedPapers.count == 1,
               let paperIndex = project.papers.firstIndex(where: { $0.id == selectedPapers.first! }) {
                openWindow(value: project.papers[paperIndex])
                project.papers[paperIndex].read = true
            }
        }
        .navigationTitle($project.name)
#if os(macOS)
        .navigationSubtitle(project.desc)
#endif
        .toolbar {
            ToolbarItemGroup {
                if project.remoteId == nil {
                    Button("Share", systemImage: "square.and.arrow.up") {
                        isShowingSharePopover.toggle()
                    }
                    .popover(isPresented: $isShowingSharePopover, arrowEdge: .bottom) {
                        VStack {
                            Image(systemName: "person.3.fill")
                                .symbolRenderingMode(.hierarchical)
                                .font(.title)
                                .foregroundStyle(Color.accentColor)
                            Text("Invite Others")
                                .font(.title2)
                                .fontWeight(.medium)
                            
                            Group {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("Invitation Code")
                                        .font(.caption)
                                    HStack {
                                        TextField("Invitation Code", text: .constant(project.invitationCode ?? ""))
                                            .textFieldStyle(.roundedBorder)
                                            .disabled(true)
                                            .frame(minWidth: 100)
                                        Button("Copy") {
                                            if let inviteCode = project.invitationCode {
                                                setPasteboard(inviteCode)
                                            }
                                        }
                                    }
                                }
                                ShareLink(
                                    "Send Invitation",
                                    item: shareURL,
                                    subject: Text(project.name),
                                    message: Text("\(username ?? String(localized: "I")) invites you to join the project \"\(project.name)\" on Paper Pilot.")
                                )
                            }
                            .disabled(project.invitationCode == nil || project.invitationCode!.isEmpty)
                        }
                        .padding()
                    }
                }
                
                Button("Project Settings", systemImage: "folder.badge.gear") {
                    isShowingEditProjectSheet.toggle()
                }
                .sheet(isPresented: $isShowingEditProjectSheet) {
                    ProjectCreateEditView(edit: true, project: project, onDelete: onDelete)
                }
                
                Button("Add Document", systemImage: "plus") {
                    isShowingAddPaperSheet.toggle()
                }
                .sheet(isPresented: $isShowingAddPaperSheet) {
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
    
    func handleDeletePaper(papers: Set<Paper.ID>, paper: Bool, pdf: Bool) {
        if pdf {
            var bookmarkStale = false
            do {
                for paperId in papers {
                    if let paper = project.papers.first(where: { $0.id == paperId }),
                       let bookmark = paper.fileBookmark,
                       let url = try? URL(resolvingBookmarkData: bookmark,
                                          options: bookmarkResOptions,
                                          relativeTo: nil,
                                          bookmarkDataIsStale: &bookmarkStale) {
                        try FileManager.default.removeItem(at: url)
                        paper.fileBookmark = nil
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        if paper {
            project.papers.removeAll { papers.contains($0.id) }
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
