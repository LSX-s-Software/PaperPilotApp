//
//  ModelStatus.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/23.
//

import SwiftUI

enum ModelStatus: Int, Codable {
    case normal = 0
    case updating = 1
    case waitingForUpload = 2
    case waitingForDownload = 3

    var icon: Image {
        switch self {
        case .normal: Image(systemName: "checkmark.icloud")
        case .updating: Image(systemName: "arrow.triangle.2.circlepath.icloud")
        case .waitingForUpload: Image(systemName: "icloud.and.arrow.up")
        case .waitingForDownload: Image(systemName: "icloud.and.arrow.down")
        }
    }
}
