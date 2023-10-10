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
    var remoteId: Int?
    var name: String
    @Attribute(originalName: "description") var desc: String
    var papers: [Paper]
    
    init(uuid: UUID = UUID(), remoteId: Int? = nil, name: String, desc: String, papers: [Paper] = []) {
        self.id = uuid
        self.remoteId = remoteId
        self.name = name
        self.desc = desc
        self.papers = papers
    }
}
