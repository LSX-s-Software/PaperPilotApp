//
//  Api.swift
//  PaperPilot
//
//  Created by mike on 2023/10/11.
//

import Foundation
import GRPC

class Api {
    static let eventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: 1, networkPreference: .best)
    static let builder = ClientConnection
        .usingPlatformAppropriateTLS(for: eventLoopGroup)
    static let channel = builder.connect(host: "paperpilot.jryang.com")

    /// GRPC client
    public static let auth = Auth_AuthPublicServiceAsyncClient(channel: channel)
    /// GRPC client
    public static let user = User_UserPublicServiceAsyncClient(channel: channel)
    /// GRPC client
    public static let project = Project_ProjectPublicServiceAsyncClient(channel: channel)
    /// GRPC client
    public static let paper = Paper_PaperPublicServiceAsyncClient(channel: channel)
}
