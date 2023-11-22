//
//  ProjectServiceTest.swift
//  PaperPilotTests
//
//  Created by 林思行 on 2023/11/22.
//

import XCTest
import SwiftData
@testable import PaperPilot

@MainActor
final class ProjectServiceTest: XCTestCase {
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

    func testGetProject() async {
        let project = Project(name: "Project", desc: "Description", invitationCode: "123456", isOwner: true)
        container.mainContext.insert(project)

        let fetchedProject = await modelService.getProject(id: project.id)
        XCTAssertEqual(fetchedProject?.id, project.id)
        XCTAssertEqual(fetchedProject?.name, project.name)
        XCTAssertEqual(fetchedProject?.desc, project.desc)
        XCTAssertEqual(fetchedProject?.invitationCode, project.invitationCode)
        XCTAssertEqual(fetchedProject?.isOwner, project.isOwner)
    }

    func testGetProjectByRemoteId() async {
        let project = Project(remoteId: "1", name: "Project", desc: "Description", invitationCode: "123456", isOwner: true)
        container.mainContext.insert(project)

        let fetchedProject = await modelService.getProject(remoteId: project.remoteId!)
        XCTAssertEqual(fetchedProject?.id, project.id)
        XCTAssertEqual(fetchedProject?.name, project.name)
        XCTAssertEqual(fetchedProject?.desc, project.desc)
        XCTAssertEqual(fetchedProject?.invitationCode, project.invitationCode)
        XCTAssertEqual(fetchedProject?.isOwner, project.isOwner)
    }

    func testGetProjectsBySet() async {
        let project1 = Project(remoteId: "1", name: "Project1", desc: "Description1")
        let project2 = Project(remoteId: "2", name: "Project2", desc: "Description2")
        let project3 = Project(remoteId: "3", name: "Project3", desc: "Description3")
        container.mainContext.insert(project1)
        container.mainContext.insert(project2)
        container.mainContext.insert(project3)

        let fetchedProjects = await modelService.getProjects(id: Set([project1.id, project2.id, UUID()]))
        XCTAssertEqual(fetchedProjects.count, 2)
        XCTAssertEqual(Set(fetchedProjects.map { $0.id }), Set([project1.id, project2.id]))
    }

    func testGetNonexistentProject() async {
        let localProject = await modelService.getProject(id: UUID())
        XCTAssertNil(localProject)
        let remoteProject = await modelService.getProject(remoteId: "123")
        XCTAssertNil(remoteProject)
    }

    func testUpdateProject() async {
        let project = Project(name: "Project", desc: "Description")
        container.mainContext.insert(project)
        let member = User_UserInfo.with {
            $0.id = "1"
            $0.username = "Test User"
            $0.avatar = "https://example.com/avatar.png"
        }
        let remote = Project_ProjectInfo.with {
            $0.id = "1"
            $0.name = "Test Project"
            $0.description_p = "Test Description"
            $0.inviteCode = "123456"
            $0.members = [member]
        }
        
        await modelService.updateProject(project, from: remote)

        XCTAssertEqual(project.remoteId, remote.id)
        XCTAssertEqual(project.name, remote.name)
        XCTAssertEqual(project.desc, remote.description_p)
        XCTAssertEqual(project.invitationCode, remote.inviteCode)
        XCTAssertEqual(project.members.count, 1)
        XCTAssertEqual(project.members.first?.id, member.id)
        XCTAssertEqual(project.members.first?.username, member.username)
        XCTAssertEqual(project.members.first?.avatar, member.avatar)
    }

    func testUpdateRemoteProjects() async throws {
        let originalProjects = [
            Project(remoteId: nil, name: "Project0", desc: "Description0"),
            Project(remoteId: "1", name: "Project1", desc: "Description1"),
            Project(remoteId: "2", name: "Project2", desc: "Description2")
        ]
        originalProjects.forEach { container.mainContext.insert($0) }
        
        let project1 = Project_ProjectInfo.with {
            $0.id = "1"
            $0.name = "Updated Project1"
            $0.description_p = "Updated Description1"
            $0.inviteCode = "654321"
        }
        let project3 = Project_ProjectInfo.with {
            $0.id = "3"
            $0.name = "New Project3"
            $0.description_p = "New Description3"
            $0.inviteCode = "123987"
        }
        
        try await modelService.updateRemoteProjects(original: originalProjects, from: [project1, project3])
        
        let localProject = await modelService.getProject(id: originalProjects[0].id)
        XCTAssertNotNil(localProject)
        XCTAssertEqual(localProject?.name, "Project0")
        XCTAssertEqual(localProject?.desc, "Description0")
        let newProject1 = await modelService.getProject(remoteId: "1")
        XCTAssertNotNil(newProject1)
        XCTAssertEqual(newProject1?.name, "Updated Project1")
        XCTAssertEqual(newProject1?.desc, "Updated Description1")
        XCTAssertEqual(newProject1?.invitationCode, "654321")
        let newProject3 = await modelService.getProject(remoteId: "3")
        XCTAssertNotNil(newProject3)
        XCTAssertEqual(newProject3?.name, "New Project3")
        XCTAssertEqual(newProject3?.desc, "New Description3")
        XCTAssertEqual(newProject3?.invitationCode, "123987")
        let project2 = await modelService.getProject(remoteId: "2")
        XCTAssertNil(project2)
    }

    func testDeleteProject_LocalOnly() async throws {
        let project = Project(remoteId: "1", name: "Test Project", desc: "Test Description")
        container.mainContext.insert(project)
        let projectDirPath = try FilePath.projectDirectory(for: project, create: true).path(percentEncoded: false)
        let projectId = project.id

        let fetchedProject = await modelService.getProject(id: projectId)
        XCTAssertNotNil(fetchedProject)
        try await modelService.deleteProject(XCTUnwrap(fetchedProject), localOnly: true)

        XCTAssertFalse(FileManager.default.fileExists(atPath: projectDirPath))
        let fetchedProject2 = await modelService.getProject(id: projectId)
        XCTAssertNil(fetchedProject2)
    }

    func testRemoveRemoteProjectsLocally() async throws {
        let project1 = Project(remoteId: nil, name: "Project1", desc: "Description1")
        container.mainContext.insert(project1)
        container.mainContext.insert(Project(remoteId: "2", name: "Project2", desc: "Description2"))
        container.mainContext.insert(Project(remoteId: "3", name: "Project3", desc: "Description3"))

        try await modelService.removeRemoteProjectsLocally()

        let fetchedProject1 = await modelService.getProject(id: project1.id)
        XCTAssertNotNil(fetchedProject1)
        XCTAssertEqual(fetchedProject1?.name, "Project1")
        XCTAssertEqual(fetchedProject1?.desc, "Description1")
        let project2 = await modelService.getProject(remoteId: "2")
        XCTAssertNil(project2)
        let project3 = await modelService.getProject(remoteId: "3")
        XCTAssertNil(project3)
    }
}
