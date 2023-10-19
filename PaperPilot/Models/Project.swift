//
//  Project.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import Foundation
import SwiftData
import SimpleCodable

/// 项目
@Model
@Codable
class Project: Hashable, Codable, Identifiable {
    @Attribute(.unique) var id: UUID
    var remoteId: String?
    /// 名称
    var name: String
    /// 描述
    @Attribute(originalName: "description") var desc: String
    /// 邀请码
    var invitationCode: String?
    // TODO: 成员列表
//    /// 成员列表
//    @Relationship(deleteRule: .cascade)
//    var members: [User]
    /// 论文列表
    @Relationship(deleteRule: .cascade)
    var papers: [Paper]
    
    init(uuid: UUID = UUID(),
         remoteId: String? = nil,
         name: String,
         desc: String,
         invitationCode: String? = nil,
         papers: [Paper] = []) {
        self.id = uuid
        self.remoteId = remoteId
        self.name = name
        self.desc = desc
        self.invitationCode = invitationCode
        self.papers = papers
    }
}
