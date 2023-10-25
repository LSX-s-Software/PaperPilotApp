//
//  Project.swift
//  PaperPilot
//
//  Created by mike on 2023/10/25.
//

import Foundation
import SwiftData

extension PPModelActor {
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
            modelContext.insert(Project(remote: from, userID: userID!))
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
