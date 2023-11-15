//
//  Spotlight.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/11/14.
//

import Foundation
import CoreSpotlight
import PDFKit

class SpotlightHelper {
    static let logger = LoggerFactory.make(category: "SpotlightHelper")

    enum IdentifierPrefix: String {
        case paper
        case project
    }
    
    /// 创建索引
    class func index(paper: Paper) {
        index(papers: [paper])
    }

    /// 批量创建索引
    class func index(papers: [Paper]) {
        let searchableItems = papers.map { paper in
            let identifier = "\(IdentifierPrefix.paper.rawValue)-\(paper.id.uuidString)"
            let attributeSet = CSSearchableItemAttributeSet(contentType: .pdf)
            attributeSet.displayName = paper.title
            attributeSet.title = paper.title
            attributeSet.contentDescription = paper.abstract ?? paper.formattedAuthors
            attributeSet.keywords = paper.tags
            attributeSet.relatedUniqueIdentifier = identifier
            attributeSet.identifier = identifier
            attributeSet.metadataModificationDate = paper.updateTime
            if let localFile = FilePath.paperFileURL(for: paper),
               let document = PDFDocument(url: localFile),
               let thumbnail = document.page(at: 0)?.thumbnail(of: CGSize(width: 180, height: 270), for: .cropBox),
               let thumbnailData = thumbnail.pngData() {
                attributeSet.thumbnailData = thumbnailData
            }

            return CSSearchableItem(uniqueIdentifier: identifier, domainIdentifier: "Paper", attributeSet: attributeSet)
        }
        CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
            if let error = error {
                Self.logger.warning("Failed to index paper: \(error)")
            }
        }
    }

    /// 创建索引
    class func index(project: Project) {
        index(projects: [project])
    }

    /// 批量创建索引
    class func index(projects: [Project]) {
        let searchableItems = projects.map { project in
            let identifier = "\(IdentifierPrefix.project.rawValue)-\(project.id.uuidString)"
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            attributeSet.displayName = project.name
            attributeSet.title = project.name
            attributeSet.contentDescription = project.desc
            attributeSet.relatedUniqueIdentifier = identifier
            attributeSet.identifier = identifier

            return CSSearchableItem(uniqueIdentifier: identifier, domainIdentifier: "Project", attributeSet: attributeSet)
        }
        CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
            if let error = error {
                Self.logger.warning("Failed to index project: \(error)")
            }
        }
    }

    /// 删除索引
    class func deleteIndex(of paper: Paper) {
        CSSearchableIndex.default()
            .deleteSearchableItems(withIdentifiers: ["\(IdentifierPrefix.paper.rawValue)-\(paper.id.uuidString)"])
    }
    
    /// 删除索引
    /// - Parameters:
    ///   - cascade: 是否级联删除项目中论文的索引
    class func deleteIndex(of project: Project, cascade: Bool = true) {
        CSSearchableIndex.default()
            .deleteSearchableItems(withIdentifiers: ["\(IdentifierPrefix.project.rawValue)-\(project.id.uuidString)"])
        if cascade {
            let paperIdentifiers = project.papers.map { "\(IdentifierPrefix.paper.rawValue)-\($0.id.uuidString)" }
            CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: paperIdentifiers)
        }
    }
}
