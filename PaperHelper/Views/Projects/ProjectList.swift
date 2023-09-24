//
//  ProjectList.swift
//  PaperHelper
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI

struct ProjectList: View {
    @State var projects = ["hello"]

    var body: some View {
        NavigationView {
            List {
                Section("本地项目") {
                    ForEach(projects, id: \.self) { item in
                        NavigationLink(item) {
                            ProjectDetail(projectName: item)
                        }
                    }
                }
            }
            .navigationTitle("项目")
            .toolbar {
                ToolbarItemGroup {
                    Spacer()
                    Button("项目", systemImage: "plus") {
                        projects.append("hello\(projects.count)")
                    }
                }
            }

            Text("从左侧列表中选择一个项目")
                .font(.title)
                .foregroundStyle(.secondary)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar, label: {
                    Image(systemName: "sidebar.leading")
                })
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
}
