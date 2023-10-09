//
//  ProjectList.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI

struct ProjectList: View {
    @EnvironmentObject var modelData: ModelData
    
    @State private var selectedProject: Project?
    @State private var isShowingLoginSheet = false
    @State private var isShowingAccountView = false
    @State private var haveLoggedIn = false
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedProject) {
                Section("Local Projects") {
                    ForEach(modelData.projects) { project in
                        NavigationLink(project.name, value: project)
                    }
                }
            }
            .navigationTitle("Projects")
            .frame(minWidth: 180)
            .toolbar {
                ToolbarItem {
                    Button("New Project", systemImage: "folder.badge.plus") {
                        modelData.projects.append(Project(id: modelData.projects.count + 1, name: "New Project", papers: []))
                    }
                }
            }
        } detail: {
            Group {
                if let project = selectedProject {
                    ProjectDetail(project: Binding { project } set: { selectedProject = $0 })
                } else {
                    Text("Select a project from the left sidebar.")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            }
            .toolbar {
                ToolbarItem(placement: selectedProject == nil ? .automatic : .principal) {
                    if !haveLoggedIn {
                        Button {
                            isShowingLoginSheet.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                Text("Login")
                            }
                        }
                        .sheet(isPresented: $isShowingLoginSheet) {
                            LoginSheet()
                        }
                    } else {
                        Button("Account", systemImage: "person.crop.circle") {
                            isShowingAccountView = true
                        }

                        .sheet(
                            isPresented: $isShowingAccountView,
                            onDismiss: {},
                            content: {
                                AccountView(
                                    isShowingAccountView:
                                        $isShowingAccountView)
                            }
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    ProjectList()
        .environmentObject(ModelData())
}
