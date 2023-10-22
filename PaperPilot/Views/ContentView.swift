//
//  ContentView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI
import SwiftData
import GRPC

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<Project> { $0.remoteId == nil }) private var localProjects: [Project]
    @Query(filter: #Predicate<Project> { $0.remoteId != nil }) private var remoteProjects: [Project]
    @State private var selectedProject: Project?
    @State private var isShowingLoginSheet = false
    @State private var isShowingAccountView = false
    @State private var isShowingNewProjectSheet = false
    @State private var isShowingJoinProjectSheet = false
    @State private var hasError = false
    @State private var errorMsg: String?
    
    @AppStorage(AppStorageKey.User.username.rawValue)
    private var username: String?
    
    var body: some View {
        NavigationSplitView {
            // MARK: - 项目列表
            List(selection: $selectedProject) {
                if !localProjects.isEmpty {
                    Section("Local Projects") {
                        ForEach(localProjects) { project in
                            NavigationLink(project.name, value: project)
                        }
                    }
                }
                
                if !remoteProjects.isEmpty {
                    Section("Remote Projects") {
                        ForEach(remoteProjects) { project in
                            NavigationLink(project.name, value: project)
                        }
                    }
                }
            }
            .navigationTitle("Projects")
            .frame(minWidth: 200)
            .overlay {
                if localProjects.isEmpty && remoteProjects.isEmpty {
                    ContentUnavailableView {
                        Label("No Project", systemImage: "folder")
                    } actions: {
                        Button("Create New Project") {
                            isShowingNewProjectSheet.toggle()
                        }
                    }
                }
            }
            // MARK: 项目列表工具栏
            .toolbar {
                ToolbarItem {
                    Menu("Add Project", systemImage: "folder.badge.plus") {
                        Button("Create New Project", systemImage: "folder.badge.plus") {
                            isShowingNewProjectSheet.toggle()
                        }
                        
                        Button("Join Project", systemImage: "folder.badge.person.crop") {
                            isShowingJoinProjectSheet.toggle()
                        }
                    }
                    .menuStyle(.button)
                    .sheet(isPresented: $isShowingNewProjectSheet) {
                        ProjectCreateEditView()
                    }
                    .sheet(isPresented: $isShowingJoinProjectSheet) {
                        JoinProjectView()
                    }
                }
            }
            // MARK: 项目列表右键菜单
            .contextMenu(forSelectionType: Project.self) { projects in
                Button("Delete") {
                    if selectedProject != nil && projects.contains(selectedProject!) {
                        selectedProject = nil
                    }
                    Task {
                        do {
                            for project in projects {
                                if let remoteId = project.remoteId {
                                    let request = Project_ProjectId.with { $0.id = remoteId }
                                    if project.isOwner {
                                        _ = try await API.shared.project.deleteProject(request)
                                    } else {
                                        _ = try await API.shared.project.quitProject(request)
                                    }
                                }
                                if let dir = try? FilePath.projectDirectory(for: project),
                                   FileManager.default.fileExists(atPath: dir.path()) {
                                    try? FileManager.default.removeItem(at: dir)
                                }
                                modelContext.delete(project)
                            }
                        } catch let error as GRPCStatus {
                            hasError = true
                            errorMsg = error.message
                        } catch {
                            hasError = true
                            errorMsg = error.localizedDescription
                        }
                    }
                }
            }
            .alert("Failed to delete project", isPresented: $hasError) {} message: {
                Text(errorMsg ?? String(localized: "Unknown error"))
            }
        } detail: {
            // MARK: - 项目详情
            Group {
                if let project = selectedProject {
                    ProjectDetail(project: project) {
                        selectedProject = nil
                    }
                } else {
                    Text("Select a project from the left sidebar.")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            }
        }
        // MARK: - 用户信息工具栏
        .toolbar {
            ToolbarItem {
                if let username = username {
                    Button {
                        isShowingLoginSheet.toggle()
                    } label: {
                        HStack {
                            AvatarView(size: 20)
                            Text(username)
                        }
                    }
                } else {
                    Button("Log In", systemImage: "person.crop.circle") {
                        isShowingLoginSheet.toggle()
                    }
                    .labelStyle(.titleAndIcon)
                }
            }
        }
        .sheet(isPresented: $isShowingLoginSheet) {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(previewContainer)
}
