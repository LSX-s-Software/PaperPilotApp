//
//  PaperServiceTest.swift
//  PaperPilotTests
//
//  Created by 林思行 on 2023/11/4.
//

import XCTest
import SwiftData
@testable import PaperPilot

@MainActor
final class PaperServiceTest: XCTestCase {
    var container: ModelContainer!
    var modelService: ModelService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        container = try ModelContainer(for: Paper.self, Project.self, Bookmark.self, User.self,
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        modelService = ModelService(modelContainer: container)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        container.deleteAllData()
    }

    func testGetPaper() async {
        let paper = Paper(title: "title")
        container.mainContext.insert(paper)

        let fetchedPaper = await modelService.getPaper(id: paper.id)
        XCTAssertEqual(fetchedPaper?.id, paper.id)
        XCTAssertEqual(fetchedPaper?.title, paper.title)
    }

    func testGetPaperByRemoteId() async {
        let paper = Paper(remoteId: "123", title: "title")
        container.mainContext.insert(paper)

        let fetchedPaper = await modelService.getPaper(remoteId: "123")

        XCTAssertEqual(fetchedPaper?.remoteId, "123")
        XCTAssertEqual(fetchedPaper?.title, paper.title)
    }

    func testGetPapersBySet() async {
        let paper1 = Paper(title: "Paper 1")
        let paper2 = Paper(title: "Paper 2")
        let paper3 = Paper(title: "Paper 3")
        container.mainContext.insert(paper1)
        container.mainContext.insert(paper2)
        container.mainContext.insert(paper3)

        let result = await modelService.getPapers(id: [paper1.id, paper2.id, UUID()])

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(Set(result.map { $0.id }), Set([paper1.id, paper2.id]))
    }

    func testGetNonexistentPaper() async {
        let localPaper = await modelService.getPaper(id: UUID())
        XCTAssertNil(localPaper)
        let remotePaper = await modelService.getPaper(remoteId: "123")
        XCTAssertNil(remotePaper)
    }

    func testUpdatePaperByPaperDetail() async {
        let paper = Paper(title: "Test Paper")
        let updateTimeSeconds = Int64(Date().timeIntervalSince1970)
        var detail = Paper_PaperDetail.with {
            $0.id = "456"
            $0.title = "Updated Test Paper"
            $0.abstract = "This is an updated test paper."
            $0.keywords = ["updated"]
            $0.authors = ["Updated Author"]
            $0.tags = ["Updated Tag"]
            $0.publicationYear = 2022
            $0.publication = "Updated Publication"
            $0.event = "Updated Event"
            $0.volume = "2"
            $0.issue = "2"
            $0.pages = "11-20"
            $0.url = "https://updated.com"
            $0.doi = "10.5678/updated"
            $0.file = "updated.pdf"
            $0.updateTime = .with {
                $0.seconds = updateTimeSeconds
            }
        }

        await modelService.updatePaper(paper, with: detail)

        XCTAssertEqual(paper.remoteId, "456")
        XCTAssertEqual(paper.title, "Updated Test Paper")
        XCTAssertEqual(paper.abstract, "This is an updated test paper.")
        XCTAssertEqual(paper.keywords, ["updated"])
        XCTAssertEqual(paper.authors, ["Updated Author"])
        XCTAssertEqual(paper.tags, ["Updated Tag"])
        XCTAssertEqual(paper.publicationYear, "2022")
        XCTAssertEqual(paper.publication, "Updated Publication")
        XCTAssertEqual(paper.event, "Updated Event")
        XCTAssertEqual(paper.volume, "2")
        XCTAssertEqual(paper.issue, "2")
        XCTAssertEqual(paper.pages, "11-20")
        XCTAssertEqual(paper.url, "https://updated.com")
        XCTAssertEqual(paper.doi, "10.5678/updated")
        XCTAssertEqual(paper.file, "updated.pdf")
        XCTAssertEqual(Int64(paper.updateTime.timeIntervalSince1970), updateTimeSeconds)

        detail.clearUpdateTime()
        await modelService.updatePaper(paper, with: detail)
        try? await Task.sleep(for: .seconds(1.1))
        XCTAssert(Int64(paper.updateTime.timeIntervalSince1970) >= updateTimeSeconds)
    }

    func testUpdatePaperByPaperDetailWithZeroPublicationYear() async {
        let paper = Paper(title: "Test Paper")
        let detail = Paper_PaperDetail.with {
            $0.id = "456"
            $0.title = "Updated Test Paper"
            $0.abstract = "This is an updated test paper."
            $0.keywords = ["updated"]
            $0.authors = ["Updated Author"]
            $0.tags = ["Updated Tag"]
            $0.publicationYear = 0
            $0.publication = "Updated Publication"
            $0.event = "Updated Event"
            $0.volume = "2"
            $0.issue = "2"
            $0.pages = "11-20"
            $0.url = "https://updated.com"
            $0.doi = "10.5678/updated"
            $0.file = "updated.pdf"
            $0.updateTime = .with {
                $0.seconds = Int64(Date().timeIntervalSince1970)
            }
        }

        await modelService.updatePaper(paper, with: detail)

        XCTAssertNil(paper.publicationYear)
    }

    func testUpdatePaper() async throws {
        let paper = Paper(title: "Test Paper")
        container.mainContext.insert(paper)
        let insertTime = paper.updateTime
        let noteUpdateTime = paper.noteUpdateTime

        try await modelService.updatePaper(paper, title: "Updated Test Paper", abstract: "This is an updated test paper.", keywords: ["updated"], authors: ["Updated Author"], tags: ["updated"], publicationYear: "2022", publication: "Updated Publication", event: "Updated Event", volume: "2", issue: "2", pages: "11-20", url: "https://updated-example.com", doi: "10.5678/updated")

        XCTAssertEqual(paper.title, "Updated Test Paper")
        XCTAssertEqual(paper.abstract, "This is an updated test paper.")
        XCTAssertEqual(paper.keywords, ["updated"])
        XCTAssertEqual(paper.authors, ["Updated Author"])
        XCTAssertEqual(paper.tags, ["updated"])
        XCTAssertEqual(paper.publicationYear, "2022")
        XCTAssertEqual(paper.publication, "Updated Publication")
        XCTAssertEqual(paper.event, "Updated Event")
        XCTAssertEqual(paper.volume, "2")
        XCTAssertEqual(paper.issue, "2")
        XCTAssertEqual(paper.pages, "11-20")
        XCTAssertEqual(paper.url, "https://updated-example.com")
        XCTAssertEqual(paper.doi, "10.5678/updated")
        XCTAssertGreaterThan(paper.updateTime, insertTime)
        XCTAssertEqual(paper.noteUpdateTime, noteUpdateTime)
    }

    func testUpdatePaperWithNote() async {
        let paper = Paper(title: "Test Paper")
        container.mainContext.insert(paper)

        let newNote = "This is a new note."
        let noteUpdateTime = Date.now
        await modelService.updatePaper(paper, note: newNote, noteUpdateTime: noteUpdateTime)

        XCTAssertEqual(paper.note, newNote)
        XCTAssertEqual(paper.noteUpdateTime, noteUpdateTime)
    }

    func testUpdatePaperWithBookmarks() async {
        let paper = Paper(title: "Test Paper")
        container.mainContext.insert(paper)

        let newBookmarks = [Bookmark(page: 1, label: "1"), Bookmark(page: 5, label: "5")]
        await modelService.updatePaper(paper, bookmarks: newBookmarks)

        XCTAssertEqual(Set(paper.bookmarks), Set(newBookmarks))
    }

    func testUpdatePaperWithNoteAndBookmarks() async {
        let paper = Paper(title: "Test Paper")
        container.mainContext.insert(paper)

        let newNote = "This is a new note."
        let noteUpdateTime = Date()
        let newBookmarks = [Bookmark(page: 1, label: "1"), Bookmark(page: 5, label: "5")]
        await modelService.updatePaper(paper, note: newNote, noteUpdateTime: noteUpdateTime, bookmarks: newBookmarks)

        XCTAssertEqual(paper.note, newNote)
        XCTAssertEqual(paper.noteUpdateTime, noteUpdateTime)
        XCTAssertEqual(Set(paper.bookmarks), Set(newBookmarks))
    }

    func testSetPaperRead() async {
        let paper = Paper(title: "Test Paper")
        container.mainContext.insert(paper)

        await modelService.setPaperRead(paper, read: true)
        XCTAssert(paper.read)

        await modelService.setPaperRead(paper, read: false)
        XCTAssertFalse(paper.read)
    }

    func testDeletePaperPDFOnly() async throws {
        let project = Project(name: "123", desc: "456")
        container.mainContext.insert(project)
        let paper = Paper(title: "Test Paper")
        container.mainContext.insert(paper)
        paper.project = project
        let url = try FilePath.paperDirectory(for: paper, create: true).appendingPathComponent("file.pdf")
        FileManager.default.createFile(atPath: url.path(percentEncoded: false), contents: "Hello".data(using: .utf8), attributes: nil)
        XCTAssert(FileManager.default.fileExists(atPath: url.path(percentEncoded: false)))
        paper.file = url.path(percentEncoded: false)
        paper.relativeLocalFile = url.lastPathComponent
        let paperId = paper.id

        let fetchedPaper = await modelService.getPaper(id: paperId)
        XCTAssertNotNil(fetchedPaper)
        try await modelService.deletePaper(fetchedPaper!, pdfOnly: true)
        XCTAssertNil(fetchedPaper!.relativeLocalFile)
        XCTAssertEqual(fetchedPaper!.status, ModelStatus.waitingForDownload.rawValue)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path(percentEncoded: false)))
        XCTAssert(FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path(percentEncoded: false)))
    }

    func testDeletePaperPDFOnlyNoRemoteFile() async throws {
        let project = Project(name: "123", desc: "456")
        container.mainContext.insert(project)
        let paper = Paper(title: "Test Paper")
        container.mainContext.insert(paper)
        paper.project = project
        let url = try FilePath.paperDirectory(for: paper, create: true).appendingPathComponent("file.pdf")
        FileManager.default.createFile(atPath: url.path(percentEncoded: false), contents: "Hello".data(using: .utf8), attributes: nil)
        XCTAssert(FileManager.default.fileExists(atPath: url.path(percentEncoded: false)))
        paper.relativeLocalFile = url.lastPathComponent
        let paperId = paper.id

        let fetchedPaper = await modelService.getPaper(id: paperId)
        XCTAssertNotNil(fetchedPaper)
        try await modelService.deletePaper(fetchedPaper!, pdfOnly: true)
        XCTAssertNil(fetchedPaper!.relativeLocalFile)
        XCTAssertEqual(fetchedPaper!.status, ModelStatus.normal.rawValue)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path(percentEncoded: false)))
        XCTAssert(FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path(percentEncoded: false)))
    }

    func testDeletePaperLocalOnly() async throws {
        let project = Project(name: "123", desc: "456")
        container.mainContext.insert(project)
        let paper = Paper(title: "Test Paper")
        container.mainContext.insert(paper)
        paper.project = project
        let url = try FilePath.paperDirectory(for: paper, create: true).appendingPathComponent("file.pdf")
        FileManager.default.createFile(atPath: url.path(percentEncoded: false), contents: "Hello".data(using: .utf8), attributes: nil)
        XCTAssert(FileManager.default.fileExists(atPath: url.path(percentEncoded: false)))
        paper.relativeLocalFile = url.lastPathComponent
        let paperId = paper.id

        var fetchedPaper = await modelService.getPaper(id: paperId)
        XCTAssertNotNil(fetchedPaper)

        try await modelService.deletePaper(fetchedPaper!, localOnly: true)
        fetchedPaper = await modelService.getPaper(id: paperId)
        XCTAssertNil(fetchedPaper)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path(percentEncoded: false)))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path(percentEncoded: false)))
    }

}
