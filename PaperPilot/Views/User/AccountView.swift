//
//  AccountView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/9.
//

import SwiftUI

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = AccountViewModel()

    @State private var isShowingLogoutConfirmation = false
    @State private var isShowingFileImporter = false

    private static let avatarSize: CGFloat = 80

    var body: some View {
        NavigationStack {
            VStack {
                if !viewModel.hasLoggedIn {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: Self.avatarSize))
                        .foregroundStyle(Color.accentColor)
                        .symbolRenderingMode(.hierarchical)
                } else {
                    AvatarView(size: Self.avatarSize)
                        .overlay(alignment: .bottomTrailing) {
                            AsyncButton(loading: $viewModel.isChangingAvatar, action: {
                                viewModel.isChangingAvatar = true
                                isShowingFileImporter = true
                            }, label: {
                                Image(systemName: "photo")
                                    .padding(4)
                                    .foregroundColor(.white)
                                    .background(.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            })
                            .buttonStyle(.plain)
                        }
                        .fileImporter(isPresented: $isShowingFileImporter,
                                      allowedContentTypes: [.image],
                                      onCompletion: viewModel.handleAvatarChange)
                }

                Group {
                    if !viewModel.hasLoggedIn {
                        Text("PaperPilot Account")
                    } else {
                        Text(verbatim: viewModel.usernameStored ?? "")
                    }
                }
                .font(.largeTitle)
                .fontWeight(.medium)
                .padding(.bottom, 1)

                Group {
                    if !viewModel.hasLoggedIn {
                        Text("Log in to collaborate with your teammates")
                    } else {
                        Text(verbatim: viewModel.phoneStored ?? "")
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
                            SecureField("New Password", text: $viewModel.newPassword)
                                .textContentType(.newPassword)
                                .textFieldStyle(InputTextFieldStyle(title: "New Password"))
                        }
                        if viewModel.isRegistering || viewModel.isEditing {
                            TextField("Verification Code", text: $viewModel.verificationCode)
                                .textContentType(.oneTimeCode)
                                .textFieldStyle(
                                    InputTextFieldWithButtonStyle(
                                        title: "Verification Code") {
                                            AsyncButton {
                                                await viewModel.sendVerificationCode()
                                            } label: {
                                                Text(viewModel.waitingForTimer ? "Retry after \(viewModel.secRemaining)s" : "Send")
                                                    .padding(.vertical, 6)
                                            }
                                            .disabled(!viewModel.canSendVerification)
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
            }
            .padding()
            .frame(width: 325)
            .toolbar {
                if viewModel.hasLoggedIn {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Log Out", role: .destructive) {
                            isShowingLogoutConfirmation = true
                        }
                        .confirmationDialog("Are you sure you want to log out?", isPresented: $isShowingLogoutConfirmation) {
                            Button("Confirm", role: .destructive, action: viewModel.logout)
                        }
                    }

                    ToolbarItem(placement: .cancellationAction) {
                        Button(viewModel.isEditing ? "Cancel" : "Edit") {
                            viewModel.isEditing.toggle()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        if viewModel.isEditing {
                            AsyncButton("Save", action: viewModel.submit)
                        } else {
                            Button(viewModel.hasLoggedIn ? "Done" : "Cancel", role: .cancel) {
                                dismiss()
                            }
                        }
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        AsyncButton(viewModel.isRegistering ? "Register" : "Login", action: viewModel.submit)
                    }
                }
            }
        }
        .alert(
            viewModel.errorMsg,
            isPresented: $viewModel.hasFailed,
            actions: { },
            message: { Text(viewModel.errorDetail ?? "No detailed error message.") })
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
    AccountView()
        .background()
        .frame(width: 325, height: 800)
}
