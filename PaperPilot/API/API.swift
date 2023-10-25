//
//  API.swift
//  PaperPilot
//
//  Created by mike on 2023/10/11.
//

import GRPC
import NIOHPACK
import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

final class API {
    static let eventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: 1, networkPreference: .best)
    static let builder = ClientConnection.usingPlatformAppropriateTLS(for: eventLoopGroup)
    let channel: ClientConnection = builder.connect(host: "paperpilot.jryang.com")

    /// GRPC Monitor public service client
    public var monitor: Monitor_MonitorPublicServiceAsyncClient
    /// GRPC Auth public service client
    public var auth: Auth_AuthPublicServiceAsyncClient
    /// GRPC User public service client
    public var user: User_UserPublicServiceAsyncClient
    /// GRPC Project public service client
    public var project: Project_ProjectPublicServiceAsyncClient
    /// GRPC Paper public service client
    public var paper: Paper_PaperPublicServiceAsyncClient
    /// GRPC Translation public service client
    public var translation: Translation_TranslationPublicServiceAsyncClient

    static var shared = API()

    @AppStorage(AppStorageKey.User.accessToken.rawValue)
    private var accessToken: String?
    @AppStorage(AppStorageKey.User.id.rawValue)
    private var id: String?
    @AppStorage(AppStorageKey.User.phone.rawValue)
    var phone: String?
    @AppStorage(AppStorageKey.User.avatar.rawValue)
    private var avatar: String?
    @AppStorage(AppStorageKey.User.username.rawValue)
    var username: String?

    init() {
        let factory = ErrorInterceptorFactory()
        self.auth = Auth_AuthPublicServiceAsyncClient(channel: channel, interceptors: factory)
        self.user = User_UserPublicServiceAsyncClient(channel: channel, interceptors: factory)
        self.project = Project_ProjectPublicServiceAsyncClient(channel: channel, interceptors: factory)
        self.paper = Paper_PaperPublicServiceAsyncClient(channel: channel, interceptors: factory)
        self.translation = Translation_TranslationPublicServiceAsyncClient(channel: channel, interceptors: factory)
        self.monitor = Monitor_MonitorPublicServiceAsyncClient(channel: channel)

#if os(macOS)
        let notification = NSApplication.willTerminateNotification
#else
        let notification = UIApplication.willTerminateNotification
#endif
        NotificationCenter.default.addObserver(forName: notification, object: nil, queue: .main ) { _ in
            do {
                try self.channel.close().wait()
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func setToken(_ accessToken: String) {
        let headers: HPACKHeaders = ["authorization": "Bearer \(accessToken)"]
        auth.defaultCallOptions.customMetadata = headers
        user.defaultCallOptions.customMetadata = headers
        project.defaultCallOptions.customMetadata = headers
        paper.defaultCallOptions.customMetadata = headers
        translation.defaultCallOptions.customMetadata = headers
    }

    func refreshUserInfo() async throws {
        let result = try await Self.shared.user.getCurrentUser(.init())
        id = result.id
        username = result.username
        phone = result.phone
        avatar = result.avatar
    }
}
