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
    
    @State var project: Project
    @State private var selection = Set<Paper.ID>()
    @State private var sortOrder = [KeyPathComparator(\Paper.formattedCreateTime)]
    
    var body: some View {
        Table(project.papers.sorted(using: sortOrder), selection: $selection, sortOrder: $sortOrder) {
            TableColumn("名称", value: \.title)
            TableColumn("作者", value: \.formattedAuthors)
            TableColumn("出版时间") { paper in
                Text(paper.publicationYear ?? "未知")
            }
            .width(50)
            TableColumn("来源") { paper in
                Text(paper.publication ?? "未知")
            }
            TableColumn("添加时间", value: \.formattedCreateTime)
                .width(90)
            TableColumn("标签") { paper in
                VFlow(alignment: .leading, spacing: 4) {
                    ForEach(paper.tags ?? [], id: \.self) { tag in
                        TagView(text: tag)
                    }
                }
                .clipped()
            }
            TableColumn("已读") { paper in
                if paper.read {
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .width(35)
        }
        .contextMenu(forSelectionType: Paper.ID.self) { selectedPapers in
            if !selectedPapers.isEmpty {
                Button("标为已读", systemImage: "checkmark.circle.fill") {
                    for paperId in selectedPapers {
                        if let index = project.papers.firstIndex(where: { $0.id == paperId }) {
                            project.papers[index].read = true
                        }
                    }
                }
                Button("标为未读", systemImage: "circle") {
                    for paperId in selectedPapers {
                        if let index = project.papers.firstIndex(where: { $0.id == paperId }) {
                            project.papers[index].read = false
                        }
                    }
                }
                Button("删除", systemImage: "trash", role: .destructive) {
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
                Button("项目设置", systemImage: "folder.badge.gear") {
                    
                }
                
                Button("添加论文", systemImage: "plus") {
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
    ProjectDetail(project: ModelData.project1)
        .frame(width: 800, height: 600)
}
