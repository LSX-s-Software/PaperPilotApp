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

    @Published var hasFailed = false
    @Published var errorMsg = ""

    @Published var secRemaining = 0
    var waitingForTimer: Bool {
        secRemaining > 0
    }
    var canSendVerification: Bool {
        !phone.isEmpty && !waitingForTimer
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

    func sendVerificationCode() async {
        do {
            let result = try await API.shared.auth.sendSmsCode(.with {
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
            let result: Auth_LoginResponse
            if self.isRegistering {
                result = try await API.shared.auth.register(.with {
                    $0.phone = self.phone
                    $0.password = self.password
                    $0.code = self.verificationCode
                    $0.username = self.username
                })
            } else {
                result = try await API.shared.auth.login(.with {
                    $0.phone = self.phone
                    $0.password = self.password
                })
            }
            DispatchQueue.main.async {
                self.accessToken = result.access.value
                self.id = result.user.id
                API.shared.setToken(result.access.value)
                self.avatar = result.user.avatar
                self.phoneStored = self.phone
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
    }
}
