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
import SwiftUI

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

    func refreshUserInfo() async -> (GRPCStatus, Exec_ApiException)? {
        let call = Self.shared.user.makeGetCurrentUserCall(.init())
        do {
            let result = try await call.response
            id = result.id
            username = result.username
            phone = result.phone
            avatar = result.avatar
            return nil
        } catch let error as GRPCStatus {
            return await call.apiException.map { (error, $0) }
        } catch {
            print(error)
            return nil
        }
    }
}

protocol WithApiException {
    var apiException: Exec_ApiException? { get async }
}

extension GRPCAsyncUnaryCall: WithApiException {
    var apiException: Exec_ApiException? {
        get async {
            do {
                return try await self.trailingMetadata.first(name: "grpc-status-details-bin").flatMap {
                    let padLen = $0.count % 4
                    let padded = $0.padding(toLength: $0.count + (padLen == 0 ? 0: (4 - padLen)), withPad: "=", startingAt: 0)
                    return Data(base64Encoded: padded)
                }.flatMap {
                    return try Google_Rpc_Status(serializedData: $0)
                        .details
                        .first { $0.typeURL == "type.googleapis.com/exec.ApiException" }
                        .map { try Exec_ApiException(serializedData: $0.value) }
                }
            } catch {
                print("Cannot parse ApiException: \(error)")
                return nil
            }
        }
    }
}
