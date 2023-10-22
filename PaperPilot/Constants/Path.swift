//
//  Path.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/22.
//

import Foundation

enum FilePath: String {
    case projectDirectory = "project"
    case paperDirectory = "paper"

    static func projectDirectory(for project: Project, create: Bool = false) throws -> URL {
        let url = try FileManager.default.url(for: .documentDirectory,
                                              in: .userDomainMask,
                                              appropriateFor: nil,
                                              create: false)
            .appending(path: Self.projectDirectory.rawValue)
            .appending(path: project.id.uuidString)
        if create {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    static func paperDirectory(for paper: Paper, create: Bool = false) throws -> URL {
        let url = try Self.projectDirectory(for: paper.project!)
            .appending(path: Self.paperDirectory.rawValue)
            .appending(path: paper.id.uuidString)
        if create {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
}
