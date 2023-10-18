//
//  ProjectCreateEditView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/10.
//

import SwiftUI
import GRPC

struct ProjectCreateEditView: View {
    var edit = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var project: Project = Project(name: "", desc: "")
    @State private var isShowingDeleteConfirm = false
    @State private var isRemoteProject = false
    @State private var submitting = false
    @State private var submitError = false
    @State private var deleting = false
    @State private var deleteError = false
    @State private var errorMsg = ""
    
    var onCreate: ((Project) -> Void)?
    var onDelete: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            ImageTitleDialog(
                title: edit ? "Edit Project" : "Create New Project",
                systemImage: "folder.fill.badge.\(edit ? "gearshape" : "plus")"
            ) {
                Form {
                    if !edit {
                        Section("Project Type") {
                            Picker("Project Type", selection: $isRemoteProject) {
                                Text("Local").tag(false)
                                Text("Remote").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }
                    }
                    
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
                .alert(edit ? "Failed to edit project" : "Failed to create project", isPresented: $submitError) {} message: {
                    Text(errorMsg)
                }
                .alert("Failed to delete project", isPresented: $deleteError) {} message: {
                    Text(errorMsg)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        handleCreateEditProject()
                    } label: {
                        if submitting {
                            ProgressView().controlSize(.mini)
                        } else {
                            Text(edit ? "Edit" : "Create")
                        }
                    }
                    .disabled(project.name.isEmpty || submitting)
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
        submitting = true
        if isRemoteProject || project.remoteId != nil {
            Task {
                do {
                    if edit {
                        _ = try await API.shared.project.updateProjectInfo(.with {
                            $0.id = project.remoteId!
                            $0.name = project.name
                            $0.description_p = project.desc
                        })
                    } else {
                        let result = try await API.shared.project.createProject(.with {
                            $0.name = project.name
                            $0.description_p = project.desc
                        })
                        project.remoteId = result.id
                        project.inviteCode = result.inviteCode
                    }
                    modelContext.insert(project)
                    dismiss()
                } catch let error as GRPCStatus {
                    submitError = true
                    errorMsg = error.message ?? String(localized: "Unknown error")
                } catch {
                    submitError = true
                    errorMsg = error.localizedDescription
                }
                submitting = false
            }
        } else {
            modelContext.insert(project)
            if !edit {
                onCreate?(project)
            }
            submitting = false
            dismiss()
        }
    }
    
    func handleDeleteProject() {
        deleting = true
        if isRemoteProject || project.remoteId != nil {
            Task {
                do {
                    _ = try await API.shared.project.deleteProject(.with {
                        $0.id = project.remoteId!
                    })
                    modelContext.delete(project)
                    onDelete?()
                    dismiss()
                } catch let error as GRPCStatus {
                    deleteError = true
                    errorMsg = error.message ?? String(localized: "Unknown error")
                } catch {
                    deleteError = true
                    errorMsg = error.localizedDescription
                }
                deleting = false
            }
        } else {
            modelContext.delete(project)
            onDelete?()
            deleting = false
            dismiss()
        }
    }
}

#Preview {
    ProjectCreateEditView()
        .modelContainer(previewContainer)
}
