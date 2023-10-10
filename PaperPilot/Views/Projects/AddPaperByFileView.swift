//
//  AddPaperByFileView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/10.
//

import SwiftUI

struct AddPaperByFileView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var project: Project
    
    @State private var title = ""
    @State private var abstract = ""
    @State private var publicationYear = ""
    @State private var publication = ""
    @State private var volume = ""
    @State private var issue = ""
    @State private var pages = ""
    @State private var doi = ""
    @State private var filePath: URL?
    
    var body: some View {
        ImageTitleDialog(title: "Add Paper By File", systemImage: "doc.badge.arrow.up") {
            Form {
                Section("Info") {
                    TextField("Title", text: $title)
                    TextField("Abstract", text: $abstract)
                    TextField("Publication Year", text: $publicationYear)
                    TextField("Publication", text: $publication)
                    TextField("Volume", text: $volume)
                    TextField("Issue", text: $issue)
                    TextField("Pages", text: $pages)
                    TextField("DOI", text: $doi)
                }
                
                Button("Choose file") {
                    let openFilePanel = NSOpenPanel()
                    openFilePanel.allowedContentTypes = [.pdf]
                    if openFilePanel.runModal() == .OK {
                        if let url = openFilePanel.url {
                            filePath = url
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    
                }
                .keyboardShortcut(.defaultAction)
                .disabled(filePath != nil)
            }
        }
    }
}

#Preview {
    AddPaperByFileView(project: ModelData.project1)
        .modelContainer(previewContainer)
}
