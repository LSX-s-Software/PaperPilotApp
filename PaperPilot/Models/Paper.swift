//
//  Paper.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import Foundation

/// 论文
struct Paper: Hashable, Codable, Identifiable {
    var id: Int
    /// 标题
    var title: String
    /// 摘要
    var abstract: String?
    /// 关键字列表
    var keywords: [String]?
    /// 作者列表
    var authors: [String]?
    var formattedAuthors: String {
        ListFormatter.localizedString(byJoining: authors ?? [])
    }
    /// tag列表
    var tags: [String]?
    /// 出版日期
    var publicationYear: Int?
    var formattedYear: String {
        publicationYear == nil ? "未知" : String(format: "%d年", publicationYear!)
    }
    /// 出版日期
    var publicationDate: Date?
    /// 出版方
    var publication: String?
    /// 卷号
    var volume: String?
    /// 期号
    var issue: String?
    /// 页码
    var pages: String?
    
    var url: String?
    var doi: String?
    
    /// 文件 url
    var file: URL?
    
    var createTime: Date = Date.now
    var formattedCreateTime: String {
        createTime.formatted(date: .abbreviated, time: .omitted)
    }
    
    /// 已读
    var read: Bool = false
}
