//
//  AccountViewModel.swift
//  PaperPilot
//
//  Created by ljx on 2023/10/12.
//

import GRPC
import SwiftUI
import SwiftData
import OSLog
import PhotosUI

class AccountViewModel: ObservableObject {
    private let logger = LoggerFactory.make(category: "AccountViewModel")

    @Published var phoneInput: String = ""
    @Published var password: String = ""
    @Published var newPassword: String = ""
    @Published var usernameInput: String = ""
    @Published var verificationCode: String = ""

    @Published var isRegistering = false
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

    @AppStorage(AppStorageKey.User.loggedIn.rawValue)
    private var loggedInStored: Bool = false
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
            logger.error("Unknown error: \(error)")
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
                let result = try await API.shared.user.updateUser(request)
                DispatchQueue.main.async {
                    self.usernameStored = result.username
                    self.phoneStored = result.phone
                    self.isEditing = false
                }
            } else {
                let result: Auth_LoginResponse
                if self.isRegistering {
                    try await result = API.shared.auth.register(.with {
                        $0.phone = self.phoneInput
                        $0.password = self.password
                        $0.code = self.verificationCode
                        $0.username = self.usernameInput
                    })
                } else {
                    result = try await API.shared.auth.login(.with {
                        $0.phone = self.phoneInput
                        $0.password = self.password
                    })
                }
                DispatchQueue.main.async {
                    self.accessToken = result.access.value
                    self.accessTokenExpireTime = Double(result.access.expireTime.seconds)
                    self.refreshToken = result.refresh.value
                    self.refreshTokenExpireTime = Double(result.refresh.expireTime.seconds)
                    self.loggedInStored = true
                    API.shared.setToken()
                    self.id = result.user.id
                    self.avatar = result.user.avatar
                    self.phoneStored = self.phoneInput
                    self.usernameStored = result.user.username
                }
            }
        } catch let error as GRPCStatus {
            apiFail(error)
        } catch {
            logger.warning("Submit Failed: \(error)")
        }
    }

    func apiFail(_ error: GRPCStatus) {
        fail(message: error.message ?? "Unknown error", detail: "")
    }

    func fail(message: String, detail: String?) {
        DispatchQueue.main.async {
            self.errorMsg = message
            self.errorDetail = detail
            self.hasFailed = true
        }
    }

    func logout() async {
        do {
            try await ModelService.shared.removeRemoteProjectsLocally()
        } catch {
            fail(message: "Cannot remove remote projects.", detail: error.localizedDescription)
        }
        
        API.shared.unsetToken()

        DispatchQueue.main.async {
            self.loggedInStored = false
            self.accessToken = nil
            self.accessTokenExpireTime = nil
            self.refreshToken = nil
            self.refreshTokenExpireTime = nil
            self.usernameStored = nil
            self.phoneStored = nil
            self.id = nil
        }
    }

    func handleAvatarChange(avatarItem: PhotosPickerItem) {
        withAnimation {
            isChangingAvatar = true
        }
        Task {
            defer {
                DispatchQueue.main.async {
                    withAnimation {
                        self.isChangingAvatar = false
                    }
                }
            }
            do {
                guard let data = try await avatarItem.loadTransferable(type: Data.self),
                      let image = PlatformImage(data: data),
                      let resizedImage = image.resized(notLargerThan: CGSize(width: 250, height: 250)) else {
                    fail(message: String(localized: "Failed to load the image."), detail: nil)
                    return
                }
#if os(macOS)
                guard let jpegData = resizedImage.jpegData() else {
                    fail(message: String(localized: "Failed to compress the image."), detail: nil)
                    return
                }
#else
                guard let jpegData = resizedImage.jpegData(compressionQuality: 0.8) else {
                    fail(message: String(localized: "Failed to compress the image."), detail: nil)
                    return
                }
#endif
                let token = try await API.shared.user.uploadUserAvatar(.init()).token
                guard let oss = OSSRequest(token: token,
                                           fileName: avatarItem.itemIdentifier ?? "",
                                           fileData: jpegData,
                                           mimeType: "image/jpeg") else {
                    logger.error("Cannot initialize OSSRequest.")
                    throw NetworkingError.responseFormatError
                }
                try await URLSession.shared.upload(for: oss)
                try await API.shared.refreshUserInfo()
            } catch let error as GRPCStatus {
                apiFail(error)
            } catch {
                fail(message: String(localized: "Failed to change avatar."), detail: error.localizedDescription)
            }
        }
    }
}
