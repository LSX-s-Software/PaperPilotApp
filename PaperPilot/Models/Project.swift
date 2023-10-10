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
    @Attribute(.unique) var id: Int
    var name: String
    var papers: [Paper]
    
    init(id: Int, name: String, papers: [Paper]) {
        self.id = id
        self.name = name
        self.papers = papers
    }
}
