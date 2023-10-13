//
//  API.swift
//  PaperPilot
//
//  Created by mike on 2023/10/11.
//

import GRPC
import AppKit
import NIOHPACK

final class API {
    static let eventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: 1, networkPreference: .best)
    static let builder = ClientConnection
        .usingPlatformAppropriateTLS(for: eventLoopGroup)
    let channel: ClientConnection = builder.connect(host: "paperpilot.jryang.com")

    /// GRPC client
    public var auth: Auth_AuthPublicServiceAsyncClient
    /// GRPC client
    public var user: User_UserPublicServiceAsyncClient
    /// GRPC client
    public var project: Project_ProjectPublicServiceAsyncClient
    /// GRPC client
    public var paper: Paper_PaperPublicServiceAsyncClient

    static var shared = API()

    init() {
        self.auth = Auth_AuthPublicServiceAsyncClient(channel: channel)
        self.user = User_UserPublicServiceAsyncClient(channel: channel)
        self.project = Project_ProjectPublicServiceAsyncClient(channel: channel)
        self.paper = Paper_PaperPublicServiceAsyncClient(channel: channel)

        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("close connection")
            do {
                try self.channel.close().wait()
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func set_token(_ accessToken: String) {
        let headers: HPACKHeaders = ["authorization": "Bearer \(accessToken)"]
        user.defaultCallOptions.customMetadata = headers
        project.defaultCallOptions.customMetadata = headers
        paper.defaultCallOptions.customMetadata = headers
    }
}
