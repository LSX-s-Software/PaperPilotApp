//
//  ShareCoordinator.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/27.
//

import ShareKit
import OSLog

class ShareCoordinator {
    private let logger = LoggerFactory.make(category: "ShareCoordinator")
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
            shareClient.connect("wss://coordinator.paperpilot.ziqiang.net.cn/") { [weak self] connection in
                self?.connection = connection
                self?.logger.info("Connected to ShareDB")
                continuation.resume()
            }
        }
    }

    /// 获取文档
    /// - Parameters:
    ///   - document: 文档名称
    ///   - collection: 文档所在集合
    ///
    /// 这个方法包含``subscribe(to:in:)-ww8k``操作。
    /// > Tip: 如果已经订阅文档，不会抛出``ShareCoordinatorError/docAlreadySubscribed``异常
    func getDocument<T: Codable>(_ key: String, in collection: ShareCollectionKey) async throws -> ShareDocument<T> {
        return try await getDocument(key, in: collection.rawValue)
    }
    
    /// 获取文档
    /// - Parameters:
    ///   - document: 文档名称
    ///   - collection: 集合名称
    ///
    /// 这个方法包含``subscribe(to:in:)-ww8k``操作。
    /// > Tip: 如果已经订阅文档，不会抛出``ShareCoordinatorError/docAlreadySubscribed``异常
    func getDocument<T: Codable>(_ key: String, in collection: String) async throws -> ShareDocument<T> {
        guard let connection = connection else { throw ShareCoordinatorError.notConnected }
        do {
            return try await subscribe(to: key, in: collection)
        } catch ShareCoordinatorError.docAlreadySubscribed {
            return try connection.getDocument(key, in: collection)
        }
    }

    /// 订阅文档
    /// - Parameters:
    ///   - document: 文档名称
    ///   - collection: 文档所在集合
    func subscribe<T: Codable>(to document: String, in collection: ShareCollectionKey) async throws -> ShareDocument<T> {
        return try await subscribe(to: document, in: collection.rawValue)
    }

    /// 订阅文档
    /// - Parameters:
    ///   - document: 文档名称
    ///   - collection: 集合名称
    func subscribe<T: Codable>(to document: String, in collection: String) async throws -> ShareDocument<T> {
        guard let connection = connection else { throw ShareCoordinatorError.notConnected }
        do {
            return try await connection.subscribe(document: document, in: collection)
        } catch ShareDocumentError.alreadySubscribed {
            throw ShareCoordinatorError.docAlreadySubscribed
        }
    }
}
