//
//  PaperExtension.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/11/14.
//

import Foundation
import SwiftData

// MARK: - Paper相关操作
extension Paper {
    var paperDetail: Paper_PaperDetail {
        Paper_PaperDetail.with {
            if let remoteId = remoteId { $0.id = remoteId }
            $0.title = title
            if let abstract = abstract { $0.abstract = abstract }
            $0.keywords = keywords
            $0.authors = authors
            $0.tags = tags
            if let publicationYear = publicationYear,
               let year = Int32(publicationYear) {
                $0.publicationYear = year
            }
            if let publication = publication { $0.publication = publication }
            if let volume = volume { $0.volume = volume }
            if let issue = issue { $0.issue = issue }
            if let pages = pages { $0.pages = pages }
            if let url = url { $0.url = url }
            if let doi = doi { $0.doi = doi }
        }
    }
}

// MARK: - Paper扩展构造函数
extension Paper {
    convenience init(from detail: Paper_PaperDetail) async {
        self.init(status: detail.file.isEmpty ? ModelStatus.normal : ModelStatus.waitingForDownload,
                  title: detail.title,
                  createTime: detail.hasCreateTime ? detail.createTime.date : Date.now)
        await ModelService.shared.updatePaper(self, with: detail)
    }

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
            throw NetworkingError.responseFormatError
        }

        // 解析论文信息
        self.init(title: title.joined(), doi: doi)
        if let subtitle = message["subtitle"] as? [String], !subtitle.isEmpty {
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
        // 解析出版物信息
        if let containerTitle = message["container-title"] as? [String] {
            self.publication = containerTitle.first
        }
        if let event = message["event"] as? [String: Any],
           let eventName = event["name"] as? String {
            self.event = eventName
        }
        if let volume = message["volume"] as? String {
            self.volume = volume
        }
        if let issue = message["issue"] as? String {
            self.issue = issue
        }
        if let page = message["page"] as? String {
            self.pages = page
        }
        // 解析URL
        if let url = message["URL"] as? String {
            self.url = url
        }
    }

    /// 通过URL获取论文信息
    /// - Parameter query: URL
    /// - Throws: NetworkingError
    convenience init(query: String, ensureDoi: Bool = false) async throws {
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
            throw NetworkingError.responseFormatError
        }

        let doi: String
        if ensureDoi {
            doi = query
        } else if let doiMatch = htmlString.firstMatch(of: /doi:(.+)&nbsp;/)?.1 {
            doi = String(doiMatch)
        } else {
            throw NetworkingError.notFound
        }
        try await self.init(doi: doi)

        if let pdfMatch = htmlString.firstMatch(of: /<iframe src="(.+)" id="pdf/) {
            self.file = String(pdfMatch.1)
            self.status = ModelStatus.waitingForDownload.rawValue
        }
    }
}
