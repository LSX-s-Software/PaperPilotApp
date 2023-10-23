//
//  ProjectCreateEditView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/10.
//

import SwiftUI
import GRPC

struct ProjectCreateEditView: View {
    var edit: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navigationContext: NavigationContext

    @Bindable var project: Project
    @State private var isShowingDeleteConfirm = false
    @State private var isRemoteProject = false
    @State private var submitError = false
    @State private var deleteError = false
    @State private var errorMsg = ""
    @State private var newName = ""
    @State private var newDesc = ""

    var onCreate: ((Project) -> Void)?
    var onDelete: (() -> Void)?

    init(edit: Bool = false,
         project: Project? = nil,
         onCreate: ((Project) -> Void)? = nil,
         onDelete: (() -> Void)? = nil) {
        self.edit = edit
        self.project = project ?? Project(name: "", desc: "")
        self._newName = State(initialValue: self.project.name)
        self._newDesc = State(initialValue: self.project.desc)
        self.onCreate = onCreate
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            ImageTitleForm(
                edit ? "Edit Project" : "Create New Project",
                systemImage: "folder.fill.badge.\(edit ? "gearshape" : "plus")"
            ) {
                TextField("Project Name", text: $newName)

                if !edit {
                    Picker("Project Type", selection: $isRemoteProject) {
                        Text("Local").tag(false)
                        Text("Remote").tag(true)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Project Description") {
                    TextEditor(text: $newDesc)
                        .font(.body)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                }
            }
            .alert(edit ? "Failed to edit project" : "Failed to create project", isPresented: $submitError) {} message: {
                Text(errorMsg)
            }
            .alert(project.isOwner ? "Failed to delete project" : "Failed to quit project",
                   isPresented: $deleteError) {} message: {
                Text(errorMsg)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    AsyncButton(edit ? "Edit" : "Create", disabled: project.name.isEmpty) {
                        await handleCreateEditProject()
                    }
                }
                if edit {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(project.isOwner ? "Delete" : "Quit", role: .destructive) {
                            isShowingDeleteConfirm.toggle()
                        }
                        .confirmationDialog("Are you sure to delete this project?", isPresented: $isShowingDeleteConfirm) {
                            AsyncButton("Delete", role: .destructive) {
                                await handleDeleteProject()
                            }
                        } message: {
                            Text("This action cannot be undone.")
                        }
                    }
                }
            }
        }
    }
    
    func handleCreateEditProject() async {
        if isRemoteProject || project.remoteId != nil {
            do {
                if edit {
                    _ = try await API.shared.project.updateProjectInfo(.with {
                        $0.id = project.remoteId!
                        $0.name = newName
                        $0.description_p = newDesc
                    })
                    project.name = newName
                    project.desc = newDesc
                } else {
                    let result = try await API.shared.project.createProject(.with {
                        $0.name = newName
                        $0.description_p = newDesc
                    })
                    project.name = newName
                    project.desc = newDesc
                    project.remoteId = result.id
                    project.invitationCode = result.inviteCode
                    modelContext.insert(project)
                }
                dismiss()
            } catch let error as GRPCStatus {
                submitError = true
                errorMsg = error.message ?? String(localized: "Unknown error")
            } catch {
                submitError = true
                errorMsg = error.localizedDescription
            }
        } else {
            project.name = newName
            project.desc = newDesc
            if !edit {
                modelContext.insert(project)
                navigationContext.selectedProject = project
                onCreate?(project)
            }
            dismiss()
        }
    }
    
    func handleDeleteProject() async {
        if isRemoteProject || project.remoteId != nil {
            do {
                let request = Project_ProjectId.with { $0.id = project.remoteId! }
                if project.isOwner {
                    _ = try await API.shared.project.deleteProject(request)
                } else {
                    _ = try await API.shared.project.quitProject(request)
                }
            } catch let error as GRPCStatus {
                deleteError = true
                errorMsg = error.message ?? String(localized: "Unknown error")
            } catch {
                deleteError = true
                errorMsg = error.localizedDescription
            }
        }
        if let dir = try? FilePath.projectDirectory(for: project),
           FileManager.default.fileExists(atPath: dir.path()) {
            try? FileManager.default.removeItem(at: dir)
        }
        navigationContext.selectedProject = nil
        onDelete?()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            modelContext.delete(project)
        }
        dismiss()
    }
}

#Preview {
    ProjectCreateEditView()
        .modelContainer(previewContainer)
}
