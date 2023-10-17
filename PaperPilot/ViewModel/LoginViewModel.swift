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
    @Published var phone: String = ""
    @Published var password: String = ""
    @Published var username: String = ""
    @Published var verificationCode: String = ""

    @Published var isRegistering = true
    @Published var isSendingVerificationCode = false
    @Published var isSubmitting = false

    @Published var hasFailed = false
    @Published var errorMsg = ""

    @Published var secRemaining = 0
    var waitingForTimer: Bool {
        secRemaining > 0
    }
    var canSendVerification: Bool {
        return !phone.isEmpty &&
        !isSendingVerificationCode &&
        !waitingForTimer
    }

    @AppStorage(AppStorageKey.User.accessToken.rawValue)
    private var accessToken: String?
    @AppStorage(AppStorageKey.User.id.rawValue)
    private var id: String?
    @AppStorage(AppStorageKey.User.phone.rawValue)
    private var phoneStored: String?
    @AppStorage(AppStorageKey.User.avatar.rawValue)
    private var avatar: String?
    @AppStorage(AppStorageKey.User.username.rawValue)
    private var usernameStored: String?

    @Binding var isShowingLoginSheet: Bool

    init(isShowingLoginSheet: Binding<Bool>) {
        self._isShowingLoginSheet = isShowingLoginSheet
    }

    func sendVerificationCode() {
        withAnimation {
            self.isSendingVerificationCode = true
        }
        Task {
            do {
                let result = try await
                API.shared.auth.sendSmsCode(Auth_SendSmsCodeRequest.with {
                    $0.phone = phone
                })
                print(result)
            } catch let error as GRPCStatus {
                DispatchQueue.main.async {
                    self.errorMsg = error.message ?? "Unknown error"
                    self.hasFailed = true
                }
            } catch {
                print(error)
            }
            DispatchQueue.main.async {
                withAnimation {
                    self.isSendingVerificationCode = false
                }
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
    }

    func submit() {
        withAnimation {
            self.isSubmitting = true
        }
        Task {
            do {
                let result: Auth_LoginResponse
                if self.isRegistering {
                    let request = User_CreateUserRequest.with {
                        $0.phone = self.phone
                        $0.password = self.password
                        $0.code = self.verificationCode
                        $0.username = self.username
                    }
                    result = try await API.shared.auth.register(request)
                } else {
                    let request = Auth_LoginRequest.with {
                        $0.phone = self.phone
                        $0.password = self.password
                    }
                    result = try await API.shared.auth.login(request)
                }
                print(result)
                DispatchQueue.main.async {
                    self.accessToken = result.access.value
                    self.id = result.user.id
                    API.shared.setToken(result.access.value)
                    self.avatar = result.user.avatar
                    self.phoneStored = self.phone
                    self.isShowingLoginSheet = false
                    self.usernameStored = result.user.username
                }
            } catch let error as GRPCStatus {
                DispatchQueue.main.async {
                    self.errorMsg = error.message ?? "Unknown error"
                    self.hasFailed = true
                }
            } catch {
                print(error)
            }
            DispatchQueue.main.async {
                withAnimation {
                    self.isSubmitting = false
                }
            }
        }
    }
}
