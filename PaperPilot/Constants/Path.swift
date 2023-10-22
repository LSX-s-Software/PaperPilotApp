//
//  Path.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/22.
//

import Foundation

enum FilePath: String {
    case paperDirectory = "paper"

    static func paperDirectory(for paper: Paper, create: Bool = false) throws -> URL {
        var url = try FileManager.default.url(for: .documentDirectory,
                                              in: .userDomainMask,
                                              appropriateFor: nil,
                                              create: false)
            .appending(path: Self.paperDirectory.rawValue)
            .appending(path: paper.id.uuidString)
        if create {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
}
