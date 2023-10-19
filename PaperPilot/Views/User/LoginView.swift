//
//  LoginView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/9.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = LoginViewModel()

    private let avatarSize: CGFloat = 80

    var body: some View {
        NavigationStack {
            VStack {
                if !viewModel.hasLoggedIn {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.accentColor)
                        .symbolRenderingMode(.hierarchical)
                } else {
                    AvatarView(size: avatarSize)
                }

                Group {
                    if !viewModel.hasLoggedIn {
                        Text("PaperPilot Account")
                    } else {
                        Text(viewModel.usernameStored ?? "")
                    }
                }
                .font(.largeTitle)
                .fontWeight(.medium)
                .padding(.bottom, 1)

                Group {
                    if !viewModel.hasLoggedIn {
                        Text("Log in to collaborate with your teammates")
                    } else {
                        Text(viewModel.phoneStored ?? "")
                    }
                }
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

                if !viewModel.hasLoggedIn {
                    Picker("Log in/Register", selection: $viewModel.isRegistering) {
                        Text("Log In").tag(false)
                        Text("Register").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                if viewModel.isEditing || !viewModel.hasLoggedIn {
                    Group {
                        if viewModel.isRegistering || viewModel.isEditing {
                            TextField("Username", text: $viewModel.usernameInput)
                                .textContentType(.username)
                                .textFieldStyle(InputTextFieldStyle(title: viewModel.isEditing ? "New Username" : "Username"))
                        }
                        TextField("Phone Number", text: $viewModel.phoneInput)
                            .textContentType(.telephoneNumber)
                            .textFieldStyle(InputTextFieldStyle(title: viewModel.isEditing ? "New Phone Numer" : "Phone Number"))
                        SecureField("Password", text: $viewModel.password)
                            .textContentType(viewModel.isRegistering ? .newPassword : .password)
                            .textFieldStyle(InputTextFieldStyle(title: viewModel.isEditing ? "Old Password" : "Password"))
                        if viewModel.isEditing {
                            SecureField("New Password", text: $viewModel.password)
                                .textContentType(.newPassword)
                                .textFieldStyle(InputTextFieldStyle(title: "New Password"))
                        }
                        if viewModel.isRegistering || viewModel.isEditing {
                            TextField("Verification Code", text: $viewModel.verificationCode)
                                .textContentType(.oneTimeCode)
                                .textFieldStyle(
                                    InputTextFieldWithButtonStyle(
                                        title: "Verification Code") {
                                            AsyncButton(controlSize: .small, disabled: !viewModel.canSendVerification) {
                                                await viewModel.sendVerificationCode()
                                            } label: {
                                                Text(viewModel.waitingForTimer ? "Retry after \(viewModel.secRemaining)s" : "Send")
                                                    .padding(.vertical, 6)
                                            }
                                        })
                            if viewModel.isEditing {
                                Text("Only required when changing the phone number.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
                HStack {
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        Group {
                            if viewModel.hasLoggedIn && !viewModel.isEditing {
                                Text("Ok")
                            } else {
                                Text("Cancel")
                            }
                        }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                    }
                    .keyboardShortcut(.cancelAction)

                    Spacer()
                        .frame(maxWidth: 40)

                    if !viewModel.hasLoggedIn || viewModel.isEditing {
                        AsyncButton(controlSize: .small) {
                            await viewModel.submit()
                        } label: {
                            Text(viewModel.isRegistering ? "Register" : "Login")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                    } else {
                        Button {
                            viewModel.isEditing = true
                        } label: {
                            Text("Edit")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .frame(width: 325)
        }
        .alert(viewModel.errorMsg, isPresented: $viewModel.hasFailed) { }
    }
}

struct InputTextFieldStyle: TextFieldStyle {
    var title: LocalizedStringKey

    func _body(configuration: TextField<Self._Label>) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            configuration
                .textFieldStyle(.plain)
                .padding(8)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct InputTextFieldWithButtonStyle<Content: View>: TextFieldStyle {
    var title: LocalizedStringKey
    @ViewBuilder var view: () -> Content

    func _body(configuration: TextField<Self._Label>) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                configuration
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                view()
            }
        }
    }
}

#Preview {
    LoginView()
        .background()
        .frame(width: 325, height: 800)
}
