//
//  ProjectExtension.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/11/14.
//

import Foundation

extension Project {
    convenience init(remote: Project_ProjectInfo, userID: String) {
        self.init(remoteId: remote.id,
                  name: remote.name,
                  desc: remote.description_p,
                  invitationCode: remote.inviteCode,
                  isOwner: remote.ownerID == userID)
    }
}
