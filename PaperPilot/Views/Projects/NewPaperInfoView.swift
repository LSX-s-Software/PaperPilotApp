//
//  NewPaperInfoView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/10.
//

import SwiftUI

struct NewPaperInfoView: View {
    @Bindable var project: Project
    @State var paper: Paper
    @Binding var shouldClose: Bool
    
    var body: some View {
        ImageTitleDialog(title: "Supplement Information", systemImage: "doc.badge.ellipsis") {
            Form {
                Section("Required Info") {
                    TextField("Title", text: $paper.title)
                }
                
                Section("Optional Info") {
                    TextField("Publication Year", text: Binding {
                        paper.publicationYear ?? ""
                    } set: {
                        paper.publicationYear = $0.isEmpty ? nil : $0
                    })
                    TextField("Publication", text: Binding {
                        paper.publication ?? ""
                    } set: {
                        paper.publication = $0.isEmpty ? nil : $0
                    })
                    TextField("Volume", text: Binding { paper.volume ?? "" } set: { paper.volume = $0.isEmpty ? nil : $0 })
                    TextField("Issue", text: Binding { paper.issue ?? "" } set: { paper.issue = $0.isEmpty ? nil : $0 })
                    TextField("Pages", text: Binding { paper.pages ?? "" } set: { paper.pages = $0.isEmpty ? nil : $0 })
                    TextField("DOI", text: Binding { paper.doi ?? "" } set: { paper.doi = $0.isEmpty ? nil : $0 })
                    TextField("Source", text: Binding { paper.source ?? "" } set: { paper.source = $0.isEmpty ? nil : $0 })
                    TextField("Abstract", text: Binding { paper.abstract ?? "" } set: { paper.abstract = $0.isEmpty ? nil : $0 })
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    project.papers.append(paper)
                    shouldClose = true
                }
                .keyboardShortcut(.defaultAction)
                .disabled(paper.title.isEmpty)
            }
        }
    }
}

#Preview {
    NewPaperInfoView(project: ModelData.project1, paper: ModelData.paper1, shouldClose: .constant(false))
        .modelContainer(previewContainer)
}
