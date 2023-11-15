//
//  Paper.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import Foundation
import SwiftData

/// 论文
@Model
class Paper: Hashable, Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    var remoteId: String?
    /// 状态
    var status: Int = ModelStatus.normal.rawValue
    /// 所属项目
    var project: Project?
    /// 标题
    var title: String
    /// 摘要
    var abstract: String?
    /// 关键字列表
    var keywords: [String]
    /// 作者列表
    var authors: [String]
    var formattedAuthors: String {
        authors.isEmpty ? String(localized: "Authors unknown") : ListFormatter.localizedString(byJoining: authors)
    }
    /// tag列表
    var tags: [String]
    /// 出版日期
    var publicationYear: String?
    /// 出版物（container title）
    var publication: String?
    /// 事件
    var event: String?
    /// 卷号
    var volume: String?
    /// 期号
    var issue: String?
    /// 页码
    var pages: String?
    
    /// 来源URL
    ///
    /// 论文来源，一般为出版商的官网
    var url: String?
    var doi: String?
    
    /// 文件URL
    ///
    /// 可下载的PDF文件的URL字符串，当本地文件不可用时可从此处获取
    var file: String?
    /// 本地文件名
    ///
    /// 已经移动到沙盒中的文件的文件名
    ///
    /// > Important: 使用前需与Paper存储目录进行拼接
    var relativeLocalFile: String?
    /// 本地临时文件URL
    ///
    /// 导入到App Group中的文件的URL
    var tempFile: URL?

    var createTime: Date
    var formattedCreateTime: String {
        createTime.formatted(date: .numeric, time: .omitted)
    }
    var updateTime: Date = Date.now

    /// 已读
    var read: Bool
    
    /// 笔记
    var note: String = ""
    var noteUpdateTime: Date = Date.now
    /// 书签
    @Relationship(deleteRule: .cascade)
    var bookmarks = [Bookmark]()
    
    init(id: UUID = UUID(),
         remoteId: String? = nil,
         status: ModelStatus = .normal,
         project: Project? = nil,
         title: String,
         abstract: String? = nil,
         keywords: [String] = [],
         authors: [String] = [],
         tags: [String] = [],
         publicationYear: String? = nil,
         publication: String? = nil,
         event: String? = nil,
         volume: String? = nil,
         issue: String? = nil,
         pages: String? = nil,
         url: String? = nil,
         doi: String? = nil,
         file: String? = nil,
         relativeLocalFile: String? = nil,
         tempFile: URL? = nil,
         createTime: Date = Date.now,
         read: Bool = false,
         note: String = "",
         bookmarks: [Bookmark] = []) {
        self.id = id
        self.remoteId = remoteId
        self.status = status.rawValue
        self.project = project
        self.title = title
        self.abstract = abstract
        self.keywords = keywords
        self.authors = authors
        self.tags = tags
        self.publicationYear = publicationYear
        self.publication = publication
        self.event = event
        self.volume = volume
        self.issue = issue
        self.pages = pages
        self.url = url
        self.doi = doi
        self.file = file
        self.relativeLocalFile = relativeLocalFile
        self.tempFile = tempFile
        self.createTime = createTime
        self.updateTime = createTime
        self.read = read
        self.note = note
        self.bookmarks = bookmarks
    }

    static let copiableProperties: [(String, PartialKeyPath)] = [("Title", \Paper.title),
                                                                 ("Abstract", \Paper.abstract),
                                                                 ("URL", \Paper.url),
                                                                 ("DOI", \Paper.doi)]
}
