//
//  Project.swift
//  PaperPilot
//
//  Created by mike on 2023/10/25.
//

import Foundation
import SwiftData

extension ModelService {
    private func updateRemoteProject(from: Project_ProjectInfo) throws {
        let remoteId = from.id

        var projects = try modelContext.fetch(FetchDescriptor(
            predicate: #Predicate<Project> { project in
                project.remoteId == remoteId
            }))
        guard projects.count <= 1 else {
            print("Error: Duplicate remote IDs.")
            return
        }
        if projects.isEmpty {
            print("insert project")
            var project = Project(remote: from, userID: userID!)
            project.members.append(contentsOf: from.members.map {User(from: $0)})
            modelContext.insert(project)
            return
        }
        let project = projects[0]
        project.update(from: from, userID: userID!)
    }

    func updateRemoteProjects(from remoteProjects: [Project_ProjectInfo]) throws {
        for remoteProject in remoteProjects {
            try updateRemoteProject(from: remoteProject)
        }
    }
}
