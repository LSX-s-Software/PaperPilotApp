//
//  Project.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import Foundation

struct Project: Hashable, Codable, Identifiable {
    var id: Int
    var name: String
    var papers: [Paper]
}
