//
//  Paper.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import Foundation

struct Paper: Hashable, Codable, Identifiable {
    var id: Int
    var name: String
    var doi: String?
    var authors: [String]?
    var formattedAuthors: String {
        ListFormatter.localizedString(byJoining: authors ?? [])
    }
    var tags: [String]?
    var keywords: [String]?
    var year: Int?
    var formattedYear: String {
        year == nil ? "未知" : String(format: "%d年", year!)
    }
    var source: String?
    var file: URL?
    var createTime: Date = Date.now
    var formattedCreateTime: String {
        createTime.formatted(date: .abbreviated, time: .omitted)
    }
    var read: Bool = false
}
