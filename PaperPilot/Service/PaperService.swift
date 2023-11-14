//
//  PaperService.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/26.
//

import Foundation
import SwiftData
import OSLog
import GRPC
import ShareKit

private let logger = Logger(subsystem: "cn.defaultlin.PaperPilotApp", category: "ModelService.PaperService")

extension ModelService {
    /// 通过ID获取Paper
    func getPaper(id: Paper.ID) -> Paper? {
        let descriptor = FetchDescriptor<Paper>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(descriptor).first
    }
    
    /// 通过remoteId获取Paper
    func getPaper(remoteId: String) -> Paper? {
        let descriptor = FetchDescriptor<Paper>(predicate: #Predicate { $0.remoteId == remoteId })
        return try? modelContext.fetch(descriptor).first
    }

    func getPapers(id: Set<Paper.ID>) -> [Paper] {
        let descriptor = FetchDescriptor<Paper>(predicate: #Predicate { id.contains($0.id) })
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// 上传Paper到服务器
    /// - Parameters:
    ///   - project: 所属项目
    ///   - parseMetadata: 是否解析元数据
    ///
    /// > Warning: 仅迁移项目更新Paper时使用，后续更新请使用``updatePaper(_:)``
    func uploadPaper(_ paper: Paper, to project: Project) async throws {
        guard let projectId = project.remoteId else { return }
        paper.status = ModelStatus.updating.rawValue
        do {
            // 上传基本信息
            if paper.remoteId == nil {
                let result = try await API.shared.paper.createPaper(.with {
                    $0.projectID = projectId
                    $0.paper = paper.paperDetail
                })
                paper.remoteId = result.id
                paper.createTime = result.createTime.date

                logger.trace("\(paper.title): Basic info uploaded")
            }
            guard let remoteId = paper.remoteId else { return }
            // 上传文件
            if let localFile = paper.localFile,
               FileManager.default.isReadableFile(atPath: localFile.path(percentEncoded: false)) {
                // 读取本地文件
                let fileData = try Data(contentsOf: localFile)
                // 获取、解析OSS直传Token
                let token = try await API.shared.paper.uploadAttachment(.with { $0.paperID = remoteId }).token
                logger.trace("\(paper.title): OSS token got")
                // 上传文件
                guard let request = OSSRequest(token: token,
                                               fileName: localFile.lastPathComponent,
                                               fileData: fileData,
                                               mimeType: "application/pdf") else {
                    throw NetworkingError.responseFormatError
                }
                try await URLSession.shared.upload(for: request)
                logger.trace("\(paper.title): File uploaded")
                // 更新文件URL
                if let newFileURL = try? await API.shared.paper.getPaper(.with { $0.id = remoteId }).file {
                    paper.file = newFileURL
                }
            }
            // 上传笔记
            if !paper.note.isEmpty {
                await ShareCoordinator.shared.connect()
                let sharedNote: ShareDocument<SharedNote> = try await ShareCoordinator.shared.getDocument(remoteId, in: .notes)
                if await sharedNote.notCreated {
                    try await sharedNote.create(SharedNote(content: paper.note))
                }
                logger.trace("\(paper.title): Notes uploaded to ShareDB")
            }
        } catch let error as GRPCStatus {
            paper.status = ModelStatus.waitingForUpload.rawValue
            throw NetworkingError.requestError(code: error.code.rawValue, message: error.message)
        } catch {
            paper.status = ModelStatus.waitingForUpload.rawValue
            throw error
        }
        paper.status = ModelStatus.normal.rawValue
    }

    /// 使用远端数据更新论文信息
    /// - Parameter detail: 远端数据
    ///
    /// > Warning: 该方法不会处理版本冲突
    func updatePaper(_ paper: Paper, with detail: Paper_PaperDetail) {
        paper.remoteId = detail.id
        paper.title = detail.title
        paper.abstract = detail.abstract
        paper.keywords = detail.keywords
        paper.authors = detail.authors
        paper.tags = detail.tags
        paper.publicationYear = detail.publicationYear == 0 ? nil : String(format: "%d", detail.publicationYear)
        paper.publication = detail.publication
        paper.event = detail.event
        paper.volume = detail.volume
        paper.issue = detail.issue
        paper.pages = detail.pages
        paper.url = detail.url
        paper.doi = detail.doi
        paper.file = detail.file
        paper.updateTime = detail.hasUpdateTime ? detail.updateTime.date : Date.now
        SpotlightHelper.index(paper: paper)
    }
    
    /// 更新论文信息
    ///
    /// 如果远程的版本比本地新，则会先使用远程数据更新本地数据，然后再将即将进行的修改提交到远程，提交成功后将修改应用到本地
    ///
    /// > Tip: 修改时只需要填写需要修改的信息
    func updatePaper(_ paper: Paper,
                     title: String? = nil,
                     abstract: String? = nil,
                     keywords: [String]? = nil,
                     authors: [String]? = nil,
                     tags: [String]? = nil,
                     publicationYear: String? = nil,
                     publication: String? = nil,
                     event: String? = nil,
                     volume: String? = nil,
                     issue: String? = nil,
                     pages: String? = nil,
                     url: String? = nil,
                     doi: String? = nil) async throws {
        let originalStatus = paper.status
        paper.status = ModelStatus.updating.rawValue
        defer {
            paper.status = originalStatus == ModelStatus.updating.rawValue ? ModelStatus.normal.rawValue : originalStatus
        }
        if let remoteId = paper.remoteId {
            // 从服务器上拉取最新的Paper
            do {
                let remotePaper = try await API.shared.paper.getPaper(.with { $0.id = remoteId })
                // 检查更新时间是否比本地新
                if remotePaper.hasUpdateTime && remotePaper.updateTime.date > paper.updateTime {
                    logger.trace("\(paper.title): Resolving conflicts")
                    updatePaper(paper, with: remotePaper)
                }
                _ = try await API.shared.paper.updatePaper(.with {
                    $0.id = remoteId
                    $0.title = title ?? paper.title
                    $0.abstract = abstract ?? paper.abstract ?? ""
                    $0.keywords = keywords ?? paper.keywords
                    $0.authors = authors ?? paper.authors
                    $0.tags = tags ?? paper.tags
                    $0.publicationYear = Int32(publicationYear ?? "0") ?? 0
                    $0.publication = publication ?? paper.publication ?? ""
                    $0.event = event ?? paper.event ?? ""
                    $0.volume = volume ?? paper.volume ?? ""
                    $0.issue = issue ?? paper.issue ?? ""
                    $0.pages = pages ?? paper.pages ?? ""
                    $0.url = url ?? paper.url ?? ""
                    $0.doi = doi ?? paper.doi ?? ""
                })
            } catch let error as GRPCStatus {
                throw NetworkingError.requestError(code: error.code.rawValue, message: error.message)
            }
        }
        if let newTitle = title { paper.title = newTitle }
        if let newAbstract = abstract { paper.abstract = newAbstract }
        if let newKeywords = keywords { paper.keywords = newKeywords }
        if let newAuthors = authors { paper.authors = newAuthors }
        if let newTags = tags { paper.tags = newTags }
        if let newPublicationYear = publicationYear { paper.publicationYear = newPublicationYear }
        if let newPublication = publication { paper.publication = newPublication }
        if let newEvent = event { paper.event = newEvent }
        if let newVolume = volume { paper.volume = newVolume }
        if let newIssue = issue { paper.issue = newIssue }
        if let newPages = pages { paper.pages = newPages }
        if let newUrl = url { paper.url = newUrl }
        if let newDoi = doi { paper.doi = newDoi }
        paper.updateTime = Date.now
        SpotlightHelper.index(paper: paper)
    }
    
    /// 更新本地缓存的论文信息
    ///
    /// > Important: 这个方法只更新缓存在本地的数据，例如笔记、书签等，不会与远程数据进行同步
    func updatePaper(_ paper: Paper,
                     note: String? = nil,
                     noteUpdateTime: Date = Date.now,
                     bookmarks: [Bookmark]? = nil) {
        if let newNote = note {
            paper.note = newNote
            paper.noteUpdateTime = noteUpdateTime
        }
        if let newBookmarks = bookmarks { paper.bookmarks = newBookmarks }
    }

    /// 设置论文的已读状态
    /// - Parameters:
    ///   - read: 是否已读
    func setPaperRead(_ paper: Paper, read: Bool) {
        paper.read = read
    }
    
    /// 删除论文
    /// - Parameters:
    ///   - pdfOnly: 仅删除本地的PDF文件
    ///
    /// > Important: 必须使用与ModelService处在同一个context下的Paper对象（可通过``getPaper(id:)``获取）
    func deletePaper(_ paper: Paper, pdfOnly: Bool = false, localOnly: Bool = false) async throws {
        if pdfOnly {
            if let url = paper.localFile,
               FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
                try FileManager.default.removeItem(at: url)
                paper.localFile = nil
                if paper.file != nil {
                    paper.status = ModelStatus.waitingForDownload.rawValue
                }
            }
        } else if let dir = try? FilePath.paperDirectory(for: paper),
                  FileManager.default.fileExists(atPath: dir.path(percentEncoded: false)) {
            try? FileManager.default.removeItem(at: dir)
        }
        if !pdfOnly {
            if !localOnly, let remoteId = paper.remoteId {
                do {
                    _ = try await API.shared.paper.deletePaper(.with { $0.id = remoteId })
                } catch let error as GRPCStatus {
                    if error.code != .notFound {
                        throw NetworkingError.requestError(code: error.code.rawValue, message: error.message)
                    }
                }
            }
            // Delete index in CoreSpotlight
            SpotlightHelper.deleteIndex(of: paper)
            paper.project?.papers.removeAll { $0.id == paper.id }
            paper.project = nil
            modelContext.delete(paper)
        }
    }
}
