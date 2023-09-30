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
    
    var body: some View {
        NavigationSplitView {
            List(modelData.projects, selection: $selectedProject) {
                project in NavigationLink(project.name, value: project)
            }
            .navigationTitle("Projects")
            .frame(minWidth: 175)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Spacer()
                    Button("New Project", systemImage: "plus") {
                        modelData.projects.append(Project(id: modelData.projects.count + 1, name: "New Project", papers: []))
                    }
                }
            }
        } detail: {
            var _ = print(selectedProject)
            if let project = selectedProject {
                ProjectDetail(project: project)
            } else {
                Text("Select a project from the left sidebar.")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func toggleSidebar() {
#if os(macOS)
        NSApp
            .keyWindow?
            .firstResponder?
            .tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
#endif
    }
}

#Preview {
    ProjectList()
        .environmentObject(ModelData())
}
