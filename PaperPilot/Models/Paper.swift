//
//  Paper.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import Foundation
import SwiftData
import SimpleCodable

/// 论文
@Model
class Paper: Hashable, Codable, Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    var remoteId: Int?
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
    var file: Data?
    
    var createTime: Date
    var formattedCreateTime: String {
        createTime.formatted(date: .numeric, time: .omitted)
    }
    
    /// 已读
    var read: Bool
    
    /// 笔记
    var note: String = ""
    /// 书签
    @Relationship(deleteRule: .cascade)
    var bookmarks = [Bookmark]()
    
    init(id: UUID = UUID(),
         remoteId: Int? = nil,
         title: String,
         abstract: String? = nil,
         keywords: [String] = [],
         authors: [String] = [],
         tags: [String] = [],
         publicationYear: String? = nil,
         publication: String? = nil,
         volume: String? = nil,
         issue: String? = nil,
         pages: String? = nil,
         url: String? = nil,
         doi: String? = nil,
         file: Data? = nil,
         createTime: Date = Date.now,
         read: Bool = false,
         note: String = "",
         bookmark: [Bookmark] = []) {
        self.id = id
        self.remoteId = remoteId
        self.title = title
        self.abstract = abstract
        self.keywords = keywords
        self.authors = authors
        self.tags = tags
        self.publicationYear = publicationYear
        self.publication = publication
        self.volume = volume
        self.issue = issue
        self.pages = pages
        self.url = url
        self.doi = doi
        self.file = file
        self.createTime = createTime
        self.read = read
        self.note = note
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case remoteId
        case title
        case abstract
        case keywords
        case authors
        case tags
        case publicationYear
        case publication
        case volume
        case issue
        case pages
        case url
        case doi
        case file
        case createTime
        case read
        case note
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.remoteId = try container.decodeIfPresent(Int.self, forKey: .remoteId)
        self.title = try container.decode(String.self, forKey: .title)
        self.abstract = try container.decodeIfPresent(String.self, forKey: .abstract)
        self.keywords = try container.decode([String].self, forKey: .keywords)
        self.authors = try container.decode([String].self, forKey: .authors)
        self.tags = try container.decode([String].self, forKey: .tags)
        self.publicationYear = try container.decodeIfPresent(String.self, forKey: .publicationYear)
        self.publication = try container.decodeIfPresent(String.self, forKey: .publication)
        self.volume = try container.decodeIfPresent(String.self, forKey: .volume)
        self.issue = try container.decodeIfPresent(String.self, forKey: .issue)
        self.pages = try container.decodeIfPresent(String.self, forKey: .pages)
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
        self.doi = try container.decodeIfPresent(String.self, forKey: .doi)
        self.file = try container.decodeIfPresent(Data.self, forKey: .file)
        self.createTime = try container.decode(Date.self, forKey: .createTime)
        self.read = try container.decode(Bool.self, forKey: .read)
        self.note = try container.decode(String.self, forKey: .note)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(remoteId, forKey: .remoteId)
        try container.encode(title, forKey: .title)
        try container.encode(abstract, forKey: .abstract)
        try container.encode(keywords, forKey: .keywords)
        try container.encode(authors, forKey: .authors)
        try container.encode(tags, forKey: .tags)
        try container.encode(publicationYear, forKey: .publicationYear)
        try container.encode(publication, forKey: .publication)
        try container.encode(volume, forKey: .volume)
        try container.encode(issue, forKey: .issue)
        try container.encode(pages, forKey: .pages)
        try container.encode(url, forKey: .url)
        try container.encode(doi, forKey: .doi)
        try container.encode(file, forKey: .file)
        try container.encode(createTime, forKey: .createTime)
        try container.encode(read, forKey: .read)
        try container.encode(note, forKey: .note)
    }
}
