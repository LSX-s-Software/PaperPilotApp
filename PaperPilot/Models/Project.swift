//
//  Project.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import Foundation
import SwiftData
import SwiftUI
import Bib

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
}
