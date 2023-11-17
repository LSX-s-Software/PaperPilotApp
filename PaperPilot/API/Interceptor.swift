//
//  Interceptor.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/25.
//

import Foundation
import GRPC
import NIOHPACK
import SwiftProtobuf

private let logger = LoggerFactory.make(category: "API")

class ErrorInterceptor<I, O>: ClientInterceptor<I, O> {
    override func receive(
        _ part: GRPCClientResponsePart<O>,
        context: ClientInterceptorContext<I, O>
    ) {
        switch part {
        case .end(var status, let trailers):
            do {
                if !status.isOk, let exception = try toException(from: trailers) {
                    logger.warning("RPC error \(exception.code): \(exception.detail)")
                    status.message = exception.message
                    context.receive(.end(status, trailers))
                }
                context.receive(part)
            } catch {
                logger.warning("failed to extract ApiException: \(error)")
            }
        default:
            context.receive(part)
        }
    }
}

// swiftlint:disable line_length
final class ErrorInterceptorFactory:
    Auth_AuthPublicServiceClientInterceptorFactoryProtocol,
    User_UserPublicServiceClientInterceptorFactoryProtocol,
    Project_ProjectPublicServiceClientInterceptorFactoryProtocol,
    Translation_TranslationPublicServiceClientInterceptorFactoryProtocol,
    Paper_PaperPublicServiceClientInterceptorFactoryProtocol,
    Monitor_MonitorPublicServiceClientInterceptorFactoryProtocol {
    private func new<I, O>() -> [GRPC.ClientInterceptor<I, O>] {
        return [ErrorInterceptor<I, O>()]
    }

    func makeGetStatusInterceptors() -> [GRPC.ClientInterceptor<SwiftProtobuf.Google_Protobuf_Empty, Monitor_ServerStatus>] {
        new()
    }

    func makeGetUserInfoInterceptors() -> [GRPC.ClientInterceptor<User_UserId, User_UserInfo>] {
        new()
    }

    func makeGetCurrentUserInterceptors() -> [GRPC.ClientInterceptor<Google_Protobuf_Empty, User_UserDetail>] {
        new()
    }

    func makeUpdateUserInterceptors() -> [GRPC.ClientInterceptor<User_UpdateUserRequest, User_UserDetail>] {
        new()
    }

    func makeUploadUserAvatarInterceptors() -> [GRPC.ClientInterceptor<Google_Protobuf_Empty, User_UploadUserAvatarResponse>] {
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

    func makeDeleteProjectInterceptors() -> [GRPC.ClientInterceptor<Project_ProjectId, Google_Protobuf_Empty>] {
        new()
    }

    func makeJoinProjectInterceptors() -> [GRPC.ClientInterceptor<Project_ProjectInviteCode, Project_ProjectInfo>] {
        new()
    }

    func makeQuitProjectInterceptors() -> [GRPC.ClientInterceptor<Project_ProjectId, Google_Protobuf_Empty>] {
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

    func makeDeletePaperInterceptors() -> [GRPC.ClientInterceptor<Paper_PaperId, Google_Protobuf_Empty>] {
        new()
    }

    func makeLoginInterceptors() -> [GRPC.ClientInterceptor<Auth_LoginRequest, Auth_LoginResponse>] {
        new()
    }

    func makeRefreshInterceptors() -> [GRPC.ClientInterceptor<Auth_RefreshTokenRequest, Auth_RefreshTokenResponse>] {
        new()
    }

    func makeLogoutInterceptors() -> [GRPC.ClientInterceptor<Google_Protobuf_Empty, Google_Protobuf_Empty>] {
        new()
    }

    func makeRegisterInterceptors() -> [GRPC.ClientInterceptor<User_CreateUserRequest, Auth_LoginResponse>] {
        new()
    }

    func makeSendSmsCodeInterceptors() -> [GRPC.ClientInterceptor<Auth_SendSmsCodeRequest, Google_Protobuf_Empty>] {
        new()
    }

    func makeCountPhoneInterceptors() -> [GRPC.ClientInterceptor<Auth_CountPhoneRequest, Auth_CountResponse>] {
        new()
    }

    func makeCountUsernameInterceptors() -> [GRPC.ClientInterceptor<Auth_CountUsernameRequest, Auth_CountResponse>] {
        new()
    }
}
// swiftlint:enable line_length
