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
    @EnvironmentObject private var navigationContext: NavigationContext
    @Environment(AppState.self) private var appState
    @State var alert = Alert()

    @Query(filter: #Predicate<Project> { $0.remoteId == nil }, animation: .default) private var localProjects: [Project]
    @Query(filter: #Predicate<Project> { $0.remoteId != nil }, animation: .default) private var remoteProjects: [Project]
    @State private var isShowingLoginSheet = false
    @State private var isShowingAccountView = false
    @State private var isShowingNewProjectSheet = false
    @State private var isShowingJoinProjectSheet = false
    @State private var hasError = false
    @State private var errorMsg: String?
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    @AppStorage(AppStorageKey.User.username.rawValue)
    private var username: String?
    
    var body: some View {
        @Bindable var appState = appState

        NavigationSplitView(columnVisibility: $columnVisibility) {
            // MARK: - 项目列表
            List(selection: $navigationContext.selectedProject) {
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
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 200, ideal: 225)
#else
            .navigationSplitViewColumnWidth(min: 225, ideal: 275)
#endif
            .overlay {
                if localProjects.isEmpty && remoteProjects.isEmpty {
                    ContentUnavailableView {
                        Label("No Project", systemImage: "folder")
                    } actions: {
                        Button("Create New Project") {
                            appState.isCreatingProject.toggle()
                        }
                    }
                }
            }
            // MARK: 项目列表工具栏
            .toolbar {
                ToolbarItem {
                    Menu("Add Project", systemImage: "folder.badge.plus") {
                        Button("Create New Project", systemImage: "plus") {
                            appState.isCreatingProject.toggle()
                        }
                        
                        Button("Join Project", systemImage: "person.crop.circle.badge.plus") {
                            isShowingJoinProjectSheet.toggle()
                        }
                    }
                    .menuStyle(.button)
                    .sheet(isPresented: $appState.isCreatingProject) {
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
                    if navigationContext.selectedProject != nil && projects.contains(navigationContext.selectedProject!) {
                        navigationContext.selectedProject = nil
                    }
                    Task {
                        do {
                            for project in await ModelService.shared.getProjects(id: Set(projects.map { $0.id })) {
                                try await ModelService.shared.deleteProject(project)
                            }
                        } catch {
                            alert.alert(message: String(localized: "Failed to delete project"),
                                        detail: error.localizedDescription)
                        }
                    }
                }
            }
        } detail: {
            // MARK: - 项目详情
            Group {
                if let project = navigationContext.selectedProject {
                    NavigationStack {
                        ProjectDetail(project: project)
                    }
                } else {
                    Text("Select a project from the left sidebar.")
                        .font(.title)
                        .foregroundStyle(.secondary)
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
        }
        .sheet(isPresented: $isShowingLoginSheet) {
            AccountView()
        }
        .alert(alert.errorMsg, isPresented: $alert.hasFailed) {} message: {
            Text(alert.errorDetail)
        }
        .environment(alert)
        .task(id: username) {
            if username == nil {
                return
            }
            let msg = String(localized: "Failed to fetch remote projects.")
            do {
                try await downloadRemoteProjects()
            } catch let error as GRPCStatus {
                alert.alert(message: msg, detail: error.message ?? "")
            } catch {
                alert.alert(message: msg, detail: error.localizedDescription)
            }
        }
        .task {
            API.shared.scheduleRefreshToken(alert: alert)
        }
    }

    func downloadRemoteProjects() async throws {
        let result = try await API.shared.project.listUserJoinedProjects(.with {
            $0.page = 0
            $0.pageSize = 0
        })
        try await ModelService.shared.updateRemoteProjects(original: remoteProjects, from: result.projects)
    }
}

#Preview {
    ContentView()
        .modelContainer(previewContainer)
}
