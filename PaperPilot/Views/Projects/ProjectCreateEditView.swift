//
//  ProjectCreateEditView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/10.
//

import SwiftUI

struct ProjectCreateEditView: View {
    var edit = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var project: Project = Project(name: "", desc: "")
    @State private var isShowingDeleteConfirm = false
    
    var body: some View {
        NavigationStack {
            ImageTitleDialog(
                title: edit ? "Edit Project" : "Create New Project",
                systemImage: "folder.fill.badge.\(edit ? "gearshape" : "plus")"
            ) {
                Form {
                    Section("Project Name") {
                        TextField("Project Name", text: $project.name)
                            .labelsHidden()
                    }
                    
                    Section("Project Description") {
                        TextEditor(text: $project.desc)
                            .font(.body)
                            .frame(minHeight: 100)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(edit ? "Edit" : "Create") {
                        handleCreateEditProject()
                    }
                }
                if edit {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Delete", role: .destructive) {
                            isShowingDeleteConfirm.toggle()
                        }
                        .confirmationDialog("Are you sure to delete this project?", isPresented: $isShowingDeleteConfirm) {
                            Button("Delete", role: .destructive) {
                                handleDeleteProject()
                            }
                        } message: {
                            Text("This action cannot be undone.")
                        }
                    }
                }
            }
        }
    }
    
    func handleCreateEditProject() {
        modelContext.insert(project)
        dismiss()
    }
    
    func handleDeleteProject() {
        modelContext.delete(project)
        dismiss()
    }
}

#Preview {
    ProjectCreateEditView()
        .modelContainer(previewContainer)
}
