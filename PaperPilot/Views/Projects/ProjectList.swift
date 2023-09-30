//
//  ProjectList.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI

struct ProjectList: View {
    @EnvironmentObject var modelData: ModelData

    var body: some View {
        NavigationView {
            List {
                Section("Local Projects") {
                    ForEach($modelData.projects) { $project in
                        NavigationLink(project.name) {
                            ProjectDetail(project: project)
                        }
                    }
                    .onDelete { indexSet in
                        modelData.projects.remove(atOffsets: indexSet)
                    }
                }
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

            Text("Select a project from the left sidebar.")
                .font(.title)
                .foregroundStyle(.secondary)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.leading")
                }
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
