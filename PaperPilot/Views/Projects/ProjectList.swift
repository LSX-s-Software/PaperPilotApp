//
//  ProjectList.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI

struct ProjectList: View {
    @EnvironmentObject var modelData: ModelData
    
    @State private var selectedProject: Project? = nil
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedProject) {
                Section("Local Projects") {
                    ForEach(modelData.projects) {
                        project in
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
            if let project = selectedProject {
                ProjectDetail(project: Binding { project } set: { selectedProject = $0 })
            } else {
                Text("Select a project from the left sidebar.")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ProjectList()
        .environmentObject(ModelData())
}
