//
//  UserExtension.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/11/14.
//

import Foundation

extension User {
    convenience init(from remote: User_UserInfo) {
        self.init(remoteId: remote.id,
                  username: remote.username,
                  avatar: remote.avatar)
    }
}
