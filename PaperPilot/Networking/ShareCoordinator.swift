//
//  ShareCoordinator.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/27.
//

import ShareKit
import OSLog

class ShareCoordinator {
    private let logger = Logger(subsystem: "cn.defaultlin.PaperPilot", category: "ShareCoordinator")
    static let shared = ShareCoordinator()

    private let shareClient = ShareClient(eventLoopGroupProvider: .createNew)
    private var connection: ShareConnection?

    private init() {}

    deinit {
        try? shareClient.syncShutdown()
    }

    func connect() async {
        if connection != nil { return }
        return await withCheckedContinuation { continuation in
            // "wss://coordinator.paperpilot.ziqiang.net.cn/"
            shareClient.connect("ws://localhost:8080") { [weak self] connection in
                self?.connection = connection
                self?.logger.info("Connected to ShareDB")
                continuation.resume()
            }
        }
    }

    /// 订阅文档
    /// - Parameters:
    ///   - document: 文档名称
    ///   - collection: 文档所在集合
    func subscribe<T: Codable>(to document: String, in collection: ShareCollectionKey) async throws -> ShareDocument<T> {
        guard let connection = connection else { throw ShareCoordinatorError.notConnected }
        return try await connection.subscribe(document: document, in: collection.rawValue)
    }

    func subscribe<T: Codable>(to document: String, in collection: String) async throws -> ShareDocument<T> {
        guard let connection = connection else { throw ShareCoordinatorError.notConnected }
        return try await connection.subscribe(document: document, in: collection)
    }
}
