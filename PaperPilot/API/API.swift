//
//  API.swift
//  PaperPilot
//
//  Created by mike on 2023/10/11.
//

import GRPC
import SwiftProtobuf
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
                return try await to_exception(from: self.trailingMetadata)
            } catch {
                print("Cannot parse ApiException: \(error)")
                return nil
            }
        }
    }
}

func to_exception(from: HPACKHeaders) throws -> Exec_ApiException? {
    print("\(from)")
    return try from.first(name: "grpc-status-details-bin").flatMap {
        let padLen = $0.count % 4
        let padded = $0.padding(toLength: $0.count + (padLen == 0 ? 0: (4 - padLen)), withPad: "=", startingAt: 0)
        print("has details")
        return Data(base64Encoded: padded)
    }.flatMap {
        print("base64 decoded")
        return try Google_Rpc_Status(serializedData: $0)
            .details
            .first { $0.typeURL == "type.googleapis.com/exec.ApiException" }
            .map {
                print("has apiexception")
                return try Exec_ApiException(serializedData: $0.value)
            }
    }
}

class ErrorInterceptor<I, O>: ClientInterceptor<I, O> {
    override func receive(
        _ part: GRPCClientResponsePart<O>,
        context: ClientInterceptorContext<I, O>
    ) {
        switch part {
        case .end(var status, let trailers):
            do {
                print("receive \(status)")
                print("\(status.isOk)")
                if !status.isOk, let exception = try to_exception(from: trailers) {
                    print("RPC error \(exception.code): \(exception.detail)")
                    status.message = exception.message
                    context.receive(.end(status, trailers))
                }
                context.receive(part)
            } catch {
                print("failed to extract ApiException: \(error)")
            }
        default:
            context.receive(part)
        }
    }
}

final class ErrorInterceptorFactory:
    Auth_AuthPublicServiceClientInterceptorFactoryProtocol,
    User_UserPublicServiceClientInterceptorFactoryProtocol,
    Project_ProjectPublicServiceClientInterceptorFactoryProtocol,
    Translation_TranslationPublicServiceClientInterceptorFactoryProtocol,
    Paper_PaperPublicServiceClientInterceptorFactoryProtocol
{
    private func new<I, O>() -> [GRPC.ClientInterceptor<I, O>] {
        return [ErrorInterceptor<I, O>()]
    }

    func makeGetUserInfoInterceptors() -> [GRPC.ClientInterceptor<User_UserId, User_UserInfo>] {
        new()
    }

    func makeGetCurrentUserInterceptors() -> [GRPC.ClientInterceptor<SwiftProtobuf.Google_Protobuf_Empty, User_UserDetail>] {
        new()
    }

    func makeUpdateUserInterceptors() -> [GRPC.ClientInterceptor<User_UpdateUserRequest, User_UserDetail>] {
        new()
    }

    func makeUploadUserAvatarInterceptors() -> [GRPC.ClientInterceptor<SwiftProtobuf.Google_Protobuf_Empty, User_UploadUserAvatarResponse>] {
        new()
    }

    func makeListUserJoinedProjectsInterceptors() -> [GRPC.ClientInterceptor<Project_ListProjectRequest, Project_ListProjectResponse>] {
        new()
    }

    func makeGetProjectInfoInterceptors() -> [GRPC.ClientInterceptor<Project_ProjectId, Project_ProjectInfo>] {
        new()
    }

    func makeCreateProjectInterceptors() -> [GRPC.ClientInterceptor<Project_CreateProjectRequest, Project_ProjectInfo>] {
        new()
    }

    func makeUpdateProjectInfoInterceptors() -> [GRPC.ClientInterceptor<Project_UpdateProjectRequest, Project_ProjectInfo>] {
        new()
    }

    func makeDeleteProjectInterceptors() -> [GRPC.ClientInterceptor<Project_ProjectId, SwiftProtobuf.Google_Protobuf_Empty>] {
        new()
    }

    func makeJoinProjectInterceptors() -> [GRPC.ClientInterceptor<Project_ProjectInviteCode, Project_ProjectInfo>] {
        new()
    }

    func makeQuitProjectInterceptors() -> [GRPC.ClientInterceptor<Project_ProjectId, SwiftProtobuf.Google_Protobuf_Empty>] {
        new()
    }

    func maketranslateInterceptors() -> [GRPC.ClientInterceptor<Translation_TranslationRequest, Translation_TranslationResponse>] {
        new()
    }

    func makeListPaperInterceptors() -> [GRPC.ClientInterceptor<Paper_ListPaperRequest, Paper_ListPaperResponse>] {
        new()
    }

    func makeGetPaperInterceptors() -> [GRPC.ClientInterceptor<Paper_PaperId, Paper_PaperDetail>] {
        new()
    }

    func makeCreatePaperInterceptors() -> [GRPC.ClientInterceptor<Paper_CreatePaperRequest, Paper_PaperDetail>] {
        new()
    }

    func makeCreatePaperByLinkInterceptors() -> [GRPC.ClientInterceptor<Paper_CreatePaperByLinkRequest, Paper_PaperDetail>] {
        new()
    }

    func makeUpdatePaperInterceptors() -> [GRPC.ClientInterceptor<Paper_PaperDetail, Paper_PaperDetail>] {
        new()
    }

    func makeUploadAttachmentInterceptors() -> [GRPC.ClientInterceptor<Paper_UploadAttachmentRequest, Paper_UploadAttachmentResponse>] {
        new()
    }

    func makeDeletePaperInterceptors() -> [GRPC.ClientInterceptor<Paper_PaperId, SwiftProtobuf.Google_Protobuf_Empty>] {
        new()
    }

    func makeLoginInterceptors() -> [GRPC.ClientInterceptor<Auth_LoginRequest, Auth_LoginResponse>] {
        new()
    }

    func makeRefreshInterceptors() -> [GRPC.ClientInterceptor<Auth_RefreshTokenRequest, Auth_RefreshTokenResponse>] {
        new()
    }

    func makeLogoutInterceptors() -> [GRPC.ClientInterceptor<SwiftProtobuf.Google_Protobuf_Empty, SwiftProtobuf.Google_Protobuf_Empty>] {
        new()
    }

    func makeRegisterInterceptors() -> [GRPC.ClientInterceptor<User_CreateUserRequest, Auth_LoginResponse>] {
        new()
    }

    func makeSendSmsCodeInterceptors() -> [GRPC.ClientInterceptor<Auth_SendSmsCodeRequest, SwiftProtobuf.Google_Protobuf_Empty>] {
        new()
    }

    func makeCountPhoneInterceptors() -> [GRPC.ClientInterceptor<Auth_CountPhoneRequest, Auth_CountResponse>] {
        new()
    }

    func makeCountUsernameInterceptors() -> [GRPC.ClientInterceptor<Auth_CountUsernameRequest, Auth_CountResponse>] {
        new()
    }
}
