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

    class func index(paper: Paper) {
        index(papers: [paper])
    }

    class func index(papers: [Paper]) {
        var searchableItems = papers.map { paper in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .pdf)
            attributeSet.displayName = paper.title
            attributeSet.title = paper.title
            attributeSet.contentDescription = paper.abstract ?? paper.formattedAuthors
            attributeSet.keywords = paper.tags
            attributeSet.relatedUniqueIdentifier = paper.id.uuidString
            attributeSet.identifier = paper.id.uuidString
            attributeSet.metadataModificationDate = paper.updateTime
            if let localFile = paper.localFile,
               let document = PDFDocument(url: localFile),
               let thumbnail = document.page(at: 0)?.thumbnail(of: CGSize(width: 180, height: 270), for: .cropBox),
               let thumbnailData = thumbnail.pngData() {
                attributeSet.thumbnailData = thumbnailData
            }

            return CSSearchableItem(uniqueIdentifier: paper.id.uuidString, domainIdentifier: "Paper", attributeSet: attributeSet)
        }
        CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
            if let error = error {
                Self.logger.warning("Failed to index paper: \(error)")
            }
        }
    }

    class func index(project: Project) {
        index(projects: [project])
    }

    class func index(projects: [Project]) {
        var searchableItems = projects.map { project in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            attributeSet.displayName = project.name
            attributeSet.title = project.name
            attributeSet.contentDescription = project.desc
            attributeSet.relatedUniqueIdentifier = project.id.uuidString
            attributeSet.identifier = project.id.uuidString

            return CSSearchableItem(uniqueIdentifier: project.id.uuidString,
                                    domainIdentifier: "Project",
                                    attributeSet: attributeSet)
        }
        CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
            if let error = error {
                Self.logger.warning("Failed to index project: \(error)")
            }
        }
    }

    class func deleteIndex(of paper: Paper) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [paper.id.uuidString])
    }

    class func deleteIndex(of project: Project) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [project.id.uuidString])
    }
}
