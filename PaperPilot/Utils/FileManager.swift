//
//  FileManager.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/22.
//

import Foundation

extension FileManager {
    func totalSize(atPath path: String) throws -> UInt64? {
        var isDirectory: ObjCBool = false

        guard self.fileExists(atPath: path, isDirectory: &isDirectory) else { return nil }

        if !isDirectory.boolValue {
            let attributes = try self.attributesOfItem(atPath: path)
            if let fileSize = attributes[.size] as? UInt64 {
                return fileSize
            }
        }

        var totalSize: UInt64 = 0

        if let enumerator = self.enumerator(atPath: path) {
            for case let fileURL as URL in enumerator {
                let attributes = try self.attributesOfItem(atPath: fileURL.path)
                if let fileSize = attributes[.size] as? UInt64 {
                    totalSize += fileSize
                }
            }
        }

        return totalSize
    }
}
