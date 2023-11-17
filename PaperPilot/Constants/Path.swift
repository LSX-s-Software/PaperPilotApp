//
//  Path.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/22.
//

import Foundation

private let logger = LoggerFactory.make(category: "FilePath")

enum FilePath: String {
    case projectDirectory = "project"
    case paperDirectory = "paper"

    /// 项目文件目录
    /// - Parameters:
    ///   - create: 如果文件夹不存在，是否创建目录
    static func projectDirectory(for project: Project, create: Bool = false) throws -> URL {
        let url = try FileManager.default.url(for: .documentDirectory,
                                              in: .userDomainMask,
                                              appropriateFor: nil,
                                              create: create)
            .appending(path: Self.projectDirectory.rawValue)
            .appending(path: project.id.uuidString)
        if create {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    /// 论文文件目录
    /// - Parameters:
    ///   - create: 如果文件夹不存在，是否创建目录
    static func paperDirectory(for paper: Paper, create: Bool = false) throws -> URL {
        let url = try Self.projectDirectory(for: paper.project!)
            .appending(path: Self.paperDirectory.rawValue)
            .appending(path: paper.id.uuidString)
        if create {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    static func paperFileURL(for paper: Paper) -> URL? {
        if let relativeLocalFile = paper.relativeLocalFile,
           let url = try? Self.paperDirectory(for: paper).appending(path: relativeLocalFile) {
            return url
        } else if let tempFile = paper.tempFile,
                  FileManager.default.fileExists(atPath: tempFile.path(percentEncoded: false)),
                  let paperDir = try? Self.paperDirectory(for: paper, create: true) {
            // 如果论文储存在临时文件夹，则转移到沙盒中
            do {
                let sandboxPaperURL = paperDir.appending(path: tempFile.lastPathComponent)
                try FileManager.default.moveItem(at: tempFile, to: sandboxPaperURL)
                paper.tempFile = nil
                paper.relativeLocalFile = sandboxPaperURL.lastPathComponent
                return sandboxPaperURL
            } catch {
                logger.error("Failed to move the file of paper \"\(paper.title)\" from temp folder to sandbox: \(error)")
                return nil
            }
        } else {
            return nil
        }
    }
}
