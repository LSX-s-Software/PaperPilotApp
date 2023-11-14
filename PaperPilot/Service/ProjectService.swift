//
//  Project.swift
//  PaperPilot
//
//  Created by mike on 2023/10/25.
//

import Foundation
import SwiftData
import GRPC

extension ModelService {
    /// 通过ID获取Project
    func getProject(id: Project.ID) -> Project? {
        let descriptor = FetchDescriptor<Project>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(descriptor).first
    }

    /// 通过对象ID获取Project
    func getProject(persistentId: PersistentIdentifier) -> Project? {
        return modelContext.registeredModel(for: persistentId)
    }

    /// 通过remoteId获取Project
    func getProject(remoteId: String) -> Project? {
        let descriptor = FetchDescriptor<Project>(predicate: #Predicate { $0.remoteId == remoteId })
        return try? modelContext.fetch(descriptor).first
    }

    func getProjects(id: Set<Project.ID>) -> [Project] {
        let descriptor = FetchDescriptor<Project>(predicate: #Predicate { id.contains($0.id) })
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func updateRemoteProjects(original: [Project], from projects: [Project_ProjectInfo]) async throws {
        let oldIdSet = Set(original.map { $0.remoteId })
        for projectRemoteId in oldIdSet.subtracting(projects.map { $0.id }) {
            if let projectRemoteId = projectRemoteId,
               let project = getProject(remoteId: projectRemoteId) {
                try await deleteProject(project, localOnly: true)
            }
        }
        for project in projects {
            if let localProject = getProject(remoteId: project.id) {
                updateProject(localProject, from: project)
            } else {
                let newProject = Project(remote: project, userID: userID!)
                modelContext.insert(newProject)
                newProject.members.append(contentsOf: project.members.map { User(from: $0) })
            }
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

    func updateProject(_ project: Project, from remote: Project_ProjectInfo) {
        project.remoteId = remote.id
        project.name = remote.name
        project.desc = remote.description_p
        project.invitationCode = remote.inviteCode
        project.isOwner = remote.ownerID == userID
        project.members = remote.members.map { User(from: $0) }
    }

    /// 删除项目
    ///
    /// > Important: 必须使用与ModelService处在同一个context下的Project对象（可通过``getProject(id:)``获取）
    func deleteProject(_ project: Project, localOnly: Bool = false) async throws {
        if !localOnly, let remoteId = project.remoteId {
            do {
                let request = Project_ProjectId.with { $0.id = remoteId }
                if project.isOwner {
                    _ = try await API.shared.project.deleteProject(request)
                } else {
                    _ = try await API.shared.project.quitProject(request)
                }
            } catch let error as GRPCStatus {
                throw NetworkingError.requestError(code: error.code.rawValue, message: error.message)
            }
        }
        if let dir = try? FilePath.projectDirectory(for: project),
           FileManager.default.fileExists(atPath: dir.path(percentEncoded: false)) {
            try? FileManager.default.removeItem(at: dir)
        }
        modelContext.delete(project)
    }
}
