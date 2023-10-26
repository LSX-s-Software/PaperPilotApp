//
//  Project.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import Foundation
import SwiftData
import SwiftUI

/// 项目
@Model
class Project: Hashable, Identifiable {
    @Attribute(.unique) var id: UUID
    var remoteId: String?
    /// 名称
    var name: String
    /// 描述
    @Attribute(originalName: "description") var desc: String
    /// 邀请码
    var invitationCode: String?
    /// 是否是所有者
    var isOwner: Bool
    /// 成员列表
    @Relationship(inverse: \User.projects)
    var members: [User] = []
    /// 论文列表
    @Relationship(deleteRule: .cascade, inverse: \Paper.project)
    var papers: [Paper]

    init(uuid: UUID = UUID(),
         remoteId: String? = nil,
         name: String,
         desc: String,
         invitationCode: String? = nil,
         isOwner: Bool = true,
         members: [User] = [],
         papers: [Paper] = []) {
        self.id = uuid
        self.remoteId = remoteId
        self.name = name
        self.desc = desc
        self.invitationCode = invitationCode
        self.isOwner = isOwner
        self.members = members
        self.papers = papers
    }

    init(remote: Project_ProjectInfo, userID: String) {
        self.id = UUID()
        self.remoteId = remote.id
        self.name = remote.name
        self.desc = remote.description_p
        self.invitationCode = remote.inviteCode
        self.isOwner = remote.ownerID == userID
        self.members = remote.members.map { User(from: $0) }
        self.papers = []
    }

    func update(from remote: Project_ProjectInfo, userID: String) {
        self.remoteId = remote.id
        self.name = remote.name
        self.desc = remote.description_p
        self.invitationCode = remote.inviteCode
        self.isOwner = remote.ownerID == userID
        self.members = remote.members.map { User(from: $0) }
        self.papers = []
    }
}

// MARK: - Project相关操作
extension Project {
    func upload() async throws {
        // 创建项目
        let result = try await API.shared.project.createProject(.with {
            $0.name = name
            $0.description_p = desc
        })
        remoteId = result.id
        invitationCode = result.inviteCode
        for paper in self.papers {
            paper.status = ModelStatus.waitingForUpload.rawValue
        }
    }
}

func downloadRemoteProjects() async throws {
    let result = try await API.shared.project.listUserJoinedProjects(.with {
        $0.page = 0
        $0.pageSize = 0
    })
    try await ModelService.shared.updateRemoteProjects(from: result.projects)
}
