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

    @AppStorage(AppStorageKey.User.user.rawValue)
    private var user: User?
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
                self.user = User(accessToken: result.access.value, phone: self.phone)
                API.shared.setToken(result.access.value)
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
