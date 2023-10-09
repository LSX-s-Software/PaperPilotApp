//
//  ProjectDetail.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI
import SwiftUIFlow

struct ProjectDetail: View {
    @Environment(\.openWindow) var openWindow
    
    @Binding var project: Project
    @State private var selection = Set<Paper.ID>()
    @State private var sortOrder = [KeyPathComparator(\Paper.formattedCreateTime)]
    
    var body: some View {
        Table(project.papers.sorted(using: sortOrder), selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Title", value: \.title)
            TableColumn("Authors", value: \.formattedAuthors)
            TableColumn("Publication Date") { paper in
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
                    ForEach(paper.tags ?? [], id: \.self) { tag in
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
                Button("Delete", systemImage: "trash", role: .destructive) {
                    for paperId in selectedPapers {
                        project.papers.removeAll { $0.id == paperId }
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
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Project Settings", systemImage: "folder.badge.gear") {
                    
                }
                
                Button("Add Document", systemImage: "plus") {
                    project.papers.append(Paper(id: 4, title: "New Paper"))
                }
            }
#if !os(macOS)
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
#endif
        }
    }
}

#Preview {
    ProjectDetail(project: .constant(ModelData.project1))
        .frame(width: 800, height: 600)
}
