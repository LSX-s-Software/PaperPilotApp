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

private let logger = LoggerFactory.make(category: "API")

final class API {
    static let eventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: 1, networkPreference: .best)
    static let builder = ClientConnection.usingPlatformAppropriateTLS(for: eventLoopGroup)
    let channel = builder.connect(host: "paperpilot.jryang.com")
    let gptChannel = builder.connect(host: "ai.paperpilot.ziqiang.net.cn")

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
    /// GRPC AI public service client
    public var gpt: Ai_GptServiceAsyncClient

    static var shared = API()

    @AppStorage(AppStorageKey.User.accessToken.rawValue)
    private var accessToken: String?
    @AppStorage(AppStorageKey.User.accessTokenExpireTime.rawValue)
    private var accessTokenExpireTime: Double?
    @AppStorage(AppStorageKey.User.refreshToken.rawValue)
    private var refreshToken: String?
    @AppStorage(AppStorageKey.User.refreshTokenExpireTime.rawValue)
    private var refreshTokenExpireTime: Double?

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
        self.monitor = Monitor_MonitorPublicServiceAsyncClient(channel: channel, interceptors: factory)
        self.gpt = Ai_GptServiceAsyncClient(channel: gptChannel)

#if os(macOS)
        let notification = NSApplication.willTerminateNotification
#else
        let notification = UIApplication.willTerminateNotification
#endif
        NotificationCenter.default.addObserver(forName: notification, object: nil, queue: .main) { _ in
            do {
                try self.channel.close().wait()
            } catch {
                logger.warning("Failed to close GRPC channel: \(error.localizedDescription)")
            }
        }
    }

    func setToken() {
        guard let accessToken = self.accessToken else {
            return
        }
        let headers: HPACKHeaders = ["authorization": "Bearer \(accessToken)"]
        auth.defaultCallOptions.customMetadata = headers
        user.defaultCallOptions.customMetadata = headers
        project.defaultCallOptions.customMetadata = headers
        paper.defaultCallOptions.customMetadata = headers
        translation.defaultCallOptions.customMetadata = headers
        gpt.defaultCallOptions.customMetadata = headers
    }

    func refreshUserInfo() async throws {
        let result = try await Self.shared.user.getCurrentUser(.init())
        id = result.id
        username = result.username
        phone = result.phone
        avatar = result.avatar
    }

    fileprivate func refreshAccessToken(alert: Alert) async {
        do {
            let result = try await Self.shared.auth.refresh(.with {
                $0.refresh = self.refreshToken!
            })
            self.accessToken = result.access.value
            self.accessTokenExpireTime = Double(result.access.expireTime.seconds)
            logger.trace("Refreshed access token.")
            if self.accessTokenExpireTime! > self.refreshTokenExpireTime! {
                logger.trace("Refresh token is about to expire.")
                // TODO: Ask for password
            }
            self.scheduleRefreshToken(alert: alert)
        } catch let error as GRPCStatus {
            DispatchQueue.main.async {
                alert.alert(message: String(localized: "Failed to refresh the access token."),
                            detail: error.message ?? "")
            }
        } catch {
            logger.error("Failed to refresh: \(error.localizedDescription)")
        }
    }

    func scheduleRefreshToken(alert: Alert) {
        guard self.accessToken != nil,
              let accessTokenExpireTime = accessTokenExpireTime,
              let refreshTokenExpireTime = refreshTokenExpireTime else { return }
        let accessExpireDate = Date(timeIntervalSince1970: accessTokenExpireTime)
        let refreshExpireDate = Date(timeIntervalSince1970: refreshTokenExpireTime)
        let secBeforeExpire: Double = 60.0
        if Date().advanced(by: secBeforeExpire) >= accessExpireDate {
            Task {
                await self.refreshAccessToken(alert: alert)
            }
            return
        }

        let timer = Timer(fire: refreshExpireDate.advanced(by: -secBeforeExpire),
                          interval: 0,
                          repeats: false) { _ in
                Task {
                    await self.refreshAccessToken(alert: alert)
                }
            }
        RunLoop.main.add(timer, forMode: .common)
    }
}

protocol WithApiException {
    var apiException: Exec_ApiException? { get async }
}

extension GRPCAsyncUnaryCall: WithApiException {
    var apiException: Exec_ApiException? {
        get async {
            do {
                return try await toException(from: self.trailingMetadata)
            } catch {
                logger.warning("Cannot parse ApiException: \(error)")
                return nil
            }
        }
    }
}

extension GRPCStatus {
    var apiException: Exec_ApiException? {
        try? .from(details: self.details)
    }
}

extension Exec_ApiException {
    static func from(details: String?) throws -> Self? {
        try details.flatMap {
            let padLen = $0.count % 4
            let padded = $0.padding(toLength: $0.count + (padLen == 0 ? 0: (4 - padLen)), withPad: "=", startingAt: 0)
            return Data(base64Encoded: padded)
        }.flatMap {
            return try Google_Rpc_Status(serializedData: $0)
                .details
                .first { $0.typeURL == "type.googleapis.com/exec.ApiException" }
                .map {
                    return try Exec_ApiException(serializedData: $0.value)
                }
        }
    }

}

func toException(from headers: HPACKHeaders) throws -> Exec_ApiException? {
    logger.debug("GRPC Response Header: \(headers.description)")
    return try .from(details: headers.first(name: "grpc-status-details-bin"))
}
