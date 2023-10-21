//
//  API.swift
//  PaperPilot
//
//  Created by mike on 2023/10/11.
//

import GRPC
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import NIOHPACK

final class API {
    static let eventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: 1, networkPreference: .best)
    static let builder = ClientConnection.usingPlatformAppropriateTLS(for: eventLoopGroup)
    let channel: ClientConnection = builder.connect(host: "paperpilot.jryang.com")

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

    init() {
        self.auth = Auth_AuthPublicServiceAsyncClient(channel: channel)
        self.user = User_UserPublicServiceAsyncClient(channel: channel)
        self.project = Project_ProjectPublicServiceAsyncClient(channel: channel)
        self.paper = Paper_PaperPublicServiceAsyncClient(channel: channel)
        self.translation = Translation_TranslationPublicServiceAsyncClient(channel: channel)

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
}
