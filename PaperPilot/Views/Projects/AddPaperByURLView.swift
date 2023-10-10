//
//  AddPaperByURLView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/10.
//

import SwiftUI

struct AddPaperByURLView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var project: Project
    @State private var url = ""
    
    var body: some View {
        ImageTitleDialog(title: "Add Paper By URL/DOI", systemImage: "link") {
            TextField("Please Enter URL/DOI", text: $url)
                .textFieldStyle(.roundedBorder)
                
            Text("You can also search paper using Sci-Hub supported format.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    
                }
                .keyboardShortcut(.defaultAction)
                .disabled(url.isEmpty)
            }
        }
    }
}

#Preview {
    AddPaperByURLView(project: ModelData.project1)
        .modelContainer(previewContainer)
}
