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
class Paper: Hashable, Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    var remoteId: String?
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
    var file: String?
    /// 文件书签
    var fileBookmark: Data?
    
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
         remoteId: String? = nil,
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
         file: String? = nil,
         fileBookmark: Data? = nil,
         createTime: Date = Date.now,
         read: Bool = false,
         note: String = "",
         bookmarks: [Bookmark] = []) {
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
        self.fileBookmark = fileBookmark
        self.createTime = createTime
        self.read = read
        self.note = note
        self.bookmarks = bookmarks
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.remoteId = try container.decodeIfPresent(String.self, forKey: .remoteId)
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
        self.file = try container.decodeIfPresent(String.self, forKey: .file)
        self.fileBookmark = try container.decodeIfPresent(Data.self, forKey: .fileBookmark)
        self.createTime = try container.decode(Date.self, forKey: .createTime)
        self.read = try container.decode(Bool.self, forKey: .read)
        self.note = try container.decode(String.self, forKey: .note)
    }
}

extension Paper: Codable {
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
        case fileBookmark
        case createTime
        case read
        case note
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
        try container.encode(fileBookmark, forKey: .fileBookmark)
        try container.encode(createTime, forKey: .createTime)
        try container.encode(read, forKey: .read)
        try container.encode(note, forKey: .note)
    }
}

extension Paper {
    /// 通过DOI获取论文信息
    /// - Parameter doi: 论文DOI
    /// - Throws: NetworkingError
    convenience init(doi: String) async throws {
        guard let url = URL(string: "https://api.crossref.org/works/\(doi)") else {
            throw NetworkingError.invalidURL
        }

        let data: Data, response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw NetworkingError.networkError(error)
        }
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 404 {
            throw NetworkingError.notFound
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let message = json?["message"] as? [String: Any],
              let title = message["title"] as? [String] else {
            throw NetworkingError.dataFormatError
        }
        
        // 解析论文信息
        self.init(title: title.joined(), doi: doi)
        if let subtitle = message["subtitle"] as? [String] {
            self.title += ": " + subtitle.joined()
        }
        // 解析作者
        if let authors = message["author"] as? [[String: Any]] {
            self.authors = authors.compactMap { author in
                let fullName = [author["given"] as? String, author["family"] as? String]
                    .compactMap { $0 }
                    .joined(separator: " ")
                return fullName.isEmpty ? nil : fullName
            }
        }
        // 解析出版日期
        if let published = message["published"] as? [String: Any],
           let dateParts = published["date-parts"] as? [[Int]],
           let datePart = dateParts.first,
           datePart.count > 0 {
            self.publicationYear = String(datePart[0])
        }
        // 解析出版方
        if let event = message["event"] as? [String: Any],
           let eventName = event["name"] as? String {
            self.publication = eventName
        }
        // 解析URL
        if let url = message["URL"] as? String {
            self.url = url
        }
    }
    
    /// 通过URL获取论文信息
    /// - Parameter query: URL
    /// - Throws: NetworkingError
    convenience init(query: String) async throws {
        var urlComp = URLComponents(string: "https://sci-hub.wf/")
        urlComp?.queryItems = [URLQueryItem(name: "sci-hub-plugin-check", value: nil),
                               URLQueryItem(name: "request", value: query)]
        guard let url = urlComp?.url else {
            throw NetworkingError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(for: request)
        } catch {
            throw NetworkingError.networkError(error)
        }
        
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw NetworkingError.dataFormatError
        }
        guard let doiMatch = htmlString.firstMatch(of: /doi:(.+)&nbsp;/) else {
            throw NetworkingError.notFound
        }
        try await self.init(doi: String(doiMatch.1))
        
        if let pdfMatch = htmlString.firstMatch(of: /<iframe src="(.+)" id="pdf/) {
            self.file = String(pdfMatch.1)
        }
    }
}
