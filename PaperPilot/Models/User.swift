//
//  User.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/24.
//

import SwiftData

@Model
class User: Identifiable {
    var id: String { remoteId }
    @Attribute(.unique) var remoteId: String
    /// 用户名
    var username: String
    /// 头像
    var avatar: String
    /// 项目列表
    var projects: [Project] = []

    init(remoteId: String, username: String, avatar: String? = nil) {
        self.remoteId = remoteId
        self.username = username
        self.avatar = avatar ?? "https://ui-avatars.com/api/?name=\(username.replacingOccurrences(of: " ", with: "+"))&size=120&background=random"
    }

    init(from remote: User_UserInfo) {
        self.remoteId = remote.id
        self.username = remote.username
        self.avatar = remote.avatar
    }
}
