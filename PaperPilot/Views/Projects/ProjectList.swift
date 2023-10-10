//
//  ProjectList.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI
import SwiftData

struct ProjectList: View {
    @Query private var projects: [Project]
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedProject: Project?
    @State private var isShowingNewProjectSheet = false
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedProject) {
                Section("Local Projects") {
                    ForEach(projects) { project in
                        NavigationLink(project.name, value: project)
                    }
                    .contextMenu {
                        Button("Delete") {
                            modelContext.delete(selectedProject!)
                            selectedProject = nil
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
            Group {
                if let project = selectedProject {
                    ProjectDetail(project: project)
                } else {
                    Text("Select a project from the left sidebar.")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    ProjectList()
        .modelContainer(previewContainer)
}
