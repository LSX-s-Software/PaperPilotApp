//
//  Logger.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/30.
//

import Foundation
import OSLog

class LoggerFactory {
    private static let bundleId = Bundle.main.bundleIdentifier

    private init() {}

    class func make(subsystem: String? = nil, category: String) -> Logger {
        Logger(subsystem: subsystem ?? bundleId ?? "PaperPilotApp", category: category)
    }
}
