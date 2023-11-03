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

        let projects = try modelContext.fetch(FetchDescriptor(
            predicate: #Predicate<Project> { project in
                project.remoteId == remoteId
            }))
        guard projects.count <= 1 else {
            print("Error: Duplicate remote IDs.")
            return
        }
        if projects.isEmpty {
            print("insert project")
            let project = Project(remote: from, userID: userID!)
            project.members.append(contentsOf: from.members.map {User(from: $0)})
            modelContext.insert(project)
            return
        }
        updateProject(projects[0], from: from, userID: userID!)
    }

    func updateRemoteProjects(from remoteProjects: [Project_ProjectInfo]) throws {
        for remoteProject in remoteProjects {
            try updateRemoteProject(from: remoteProject)
        }
    }

    func uploadProject(_ project: Project) async throws {
        // 创建项目
        let result = try await API.shared.project.createProject(.with {
            $0.name = project.name
            $0.description_p = project.desc
        })
        project.remoteId = result.id
        project.invitationCode = result.inviteCode
        for paper in project.papers {
            paper.status = ModelStatus.waitingForUpload.rawValue
        }
    }

    func updateProject(_ project: Project, from remote: Project_ProjectInfo, userID: String) {
        project.remoteId = remote.id
        project.name = remote.name
        project.desc = remote.description_p
        project.invitationCode = remote.inviteCode
        project.isOwner = remote.ownerID == userID
        project.members = remote.members.map { User(from: $0) }
    }
}
