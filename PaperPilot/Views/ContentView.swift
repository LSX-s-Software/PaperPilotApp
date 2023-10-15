//
//  ContentView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var projects: [Project]
    @State private var selectedProject: Project?
    @State private var isShowingLoginSheet = false
    @State private var isShowingAccountView = false
    @State private var isShowingNewProjectSheet = false
    
    @AppStorage(AppStorageKey.User.username.rawValue)
    private var username: String?
    
    var body: some View {
        NavigationSplitView {
            // MARK: - 项目列表
            List(selection: $selectedProject) {
                Section("Local Projects") {
                    ForEach(projects) { project in
                        NavigationLink(project.name, value: project)
                            .contextMenu {
                                Button("Delete") {
                                    modelContext.delete(project)
                                    if selectedProject != nil && selectedProject!.id == project.id {
                                        selectedProject = nil
                                    }
                                }
                            }
                    }
                }
            }
            .navigationTitle("Projects")
            .frame(minWidth: 180)
            .toolbar {
                ToolbarItem {
                    Button("New Project", systemImage: "folder.badge.plus") {
                        isShowingNewProjectSheet.toggle()
                    }
                    .sheet(isPresented: $isShowingNewProjectSheet) {
                        ProjectCreateEditView()
                    }
                }
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
        // MARK: - Toolbar
        .toolbar {
            ToolbarItem {
                if username != nil {
                    Button("Account", systemImage: "person.crop.circle") {
                        isShowingAccountView.toggle()
                    }
                    .sheet(isPresented: $isShowingAccountView) {
                        AccountView()
                    }
                } else {
                    Button {
                        isShowingLoginSheet.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text("Log In")
                        }
                    }
                    .sheet(isPresented: $isShowingLoginSheet) {
                        LoginView(viewModel: LoginViewModel(isShowingLoginSheet: $isShowingLoginSheet))
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(previewContainer)
}
