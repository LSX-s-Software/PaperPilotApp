//
//  LoginViewModel.swift
//  PaperPilot
//
//  Created by ljx on 2023/10/12.
//

import Foundation
import GRPC
import SwiftUI
import SwiftData

class LoginViewModel: ObservableObject {
    @Published var phoneInput: String = ""
    @Published var password: String = ""
    @Published var newPassword: String = ""
    @Published var usernameInput: String = ""
    @Published var verificationCode: String = ""

    @Published var isRegistering = true
    var hasLoggedIn: Bool {
        accessToken != nil
    }
    @Published var isEditing = false
    @Published var isChangingAvatar = false

    var newPrefix: String {
        isEditing ? "New " : ""
    }

    @Published var hasFailed = false
    @Published var errorMsg = ""
    @Published var errorDetail: String?

    @Published var secRemaining = 0
    var waitingForTimer: Bool {
        secRemaining > 0
    }
    var canSendVerification: Bool {
        !phoneInput.isEmpty && !waitingForTimer
    }

    @AppStorage(AppStorageKey.User.accessToken.rawValue)
    private var accessToken: String?
    @AppStorage(AppStorageKey.User.id.rawValue)
    private var id: String?
    @AppStorage(AppStorageKey.User.phone.rawValue)
    var phoneStored: String?
    @AppStorage(AppStorageKey.User.avatar.rawValue)
    private var avatar: String?
    @AppStorage(AppStorageKey.User.username.rawValue)
    var usernameStored: String?

    func sendVerificationCode() async {
        do {
            _ = try await API.shared.auth.sendSmsCode(.with {
                $0.phone = phoneInput
            })
        } catch let error as GRPCStatus {
            DispatchQueue.main.async {
                self.errorMsg = error.message ?? "Unknown error"
                self.hasFailed = true
            }
        } catch {
            print(error)
        }
        DispatchQueue.main.async {
            self.secRemaining = 60
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if self.secRemaining == 0 {
                    timer.invalidate()
                } else {
                    self.secRemaining -= 1
                }
            }
        }
    }

    func submit() async {
        var anyCall: WithApiException?
        do {
            if self.isEditing {
                let request = User_UpdateUserRequest.with {
                    $0.id = id!
                    $0.username = usernameInput.isEmpty ? usernameStored! : usernameInput
                    $0.oldPassword = password
                    $0.newPassword = newPassword
                    $0.phone = phoneInput.isEmpty ? phoneStored! : phoneInput
                    $0.code = verificationCode
                }
                let call = API.shared.user.makeUpdateUserCall(request)
                anyCall = call
                let result = try await call.response
                DispatchQueue.main.async {
                    self.usernameStored = result.username
                    self.phoneStored = result.phone
                    self.isEditing = false
                }
            } else {
                let result: Auth_LoginResponse
                if self.isRegistering {
                    let call = API.shared.auth.makeRegisterCall(.with {
                        $0.phone = self.phoneInput
                        $0.password = self.password
                        $0.code = self.verificationCode
                        $0.username = self.usernameInput
                    })
                    anyCall = call
                    result = try await call.response
                } else {
                    let call = API.shared.auth.makeLoginCall(.with {
                        $0.phone = self.phoneInput
                        $0.password = self.password
                    })
                    anyCall = call
                    result = try await call.response
                }
                DispatchQueue.main.async {
                    self.accessToken = result.access.value
                    API.shared.setToken(result.access.value)
                    self.id = result.user.id
                    self.avatar = result.user.avatar
                    self.phoneStored = self.phoneInput
                    self.usernameStored = result.user.username
                }
            }
        } catch let error as GRPCStatus {
            await apiFail(anyCall, error)
        } catch {
            print(error)
        }
    }

    func apiFail(_ call: (any WithApiException)?, _ error: GRPCStatus) async {
        let detail = await call?.apiException?.message
        fail(message: error.message ?? "Unknown error", detail: detail)
    }

    func fail(message: String, detail: String?) {
        DispatchQueue.main.async {
            self.errorMsg = message
            self.errorDetail = detail
            self.hasFailed = true
        }
    }

    func logout() {
        self.accessToken = nil
        self.usernameStored = nil
        self.phoneStored = nil
        self.usernameStored = nil
    }

    private func getAvatarOSSToken() async throws -> Util_OssToken? {
        let call = API.shared.user.makeUploadUserAvatarCall(.init())
        do {
            return try await call.response.token
        } catch let error as GRPCStatus {
            await apiFail(call, error)
            return nil
        }
    }

    func handleAvatarChange(result: Result<URL, Error>) {
        let errorChooseImageMsg = String(localized: "Failed to choose an image file.")
        switch result {
        case .success(let url):
            let gotAccess = url.startAccessingSecurityScopedResource()
            if !gotAccess {
                fail(message: errorChooseImageMsg, detail: String(localized: "Cannot access the file."))
                return
            }
            let getTokenTask = Task { return try await getAvatarOSSToken() }
            let session = URLSession(configuration: .default)
            let request = URLRequest(url: url)
            let dataTask = Task { return try await session.data(for: request) }
            Task {
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                do {
                    guard let token = try await getTokenTask.value else {
                        return
                    }
                    let (data, response) = try await dataTask.value
                    let filename = response.suggestedFilename
                    guard let oss =
                            OSSRequest(
                                token: token,
                                fileName: filename ?? "",
                                fileData: data,
                                mimeType: "image/jpeg"
                            ) else {
                        print("invalid token \(token)")
                        return
                    }
                    try await URLSession.shared.upload(for: oss)
                    if let (error, exception) = await API.shared.refreshUserInfo() {
                        fail(message: error.localizedDescription, detail: exception.message)
                    }
                    DispatchQueue.main.async {
                        self.isChangingAvatar = false
                    }
                } catch let error as URLError {
                    print(error)
                } catch NetworkingError.requestError(_, let message) {
                    fail(message: String(localized: "Failed to upload the image."), detail: message)
                } catch {
                    print(error)
                }
            }
        case .failure(let error):
            fail(message: errorChooseImageMsg, detail: error.localizedDescription)
            self.isChangingAvatar = false
        }
    }
}
