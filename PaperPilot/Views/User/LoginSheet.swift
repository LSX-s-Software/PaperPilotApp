//
//  LoginSheet.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/9.
//

import SwiftUI

struct LoginSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var phone = ""
    @State private var password = ""
    @ObservedObject var viewModel = LoginViewModel()
    
    @AppStorage(AppStorageKey.User.loggedIn.rawValue)
    private var loggedIn = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                    .symbolRenderingMode(.hierarchical)
                Text("PaperPilot Account")
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .padding(.bottom, 1)
                Text("Log in to collaborate with your teammates")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Picker("", selection: $viewModel.isRegistering) {
                    Text("Log In").tag(false)
                    Text("Register").tag(true)
                }
                .pickerStyle(.segmented)
                Group {
                    if viewModel.isRegistering {
                        TextField("Username", text: $viewModel.username)
                            .textContentType(.username)
                            .textFieldStyle(InputTextFieldStyle(title: "Username"))
                    }
                    TextField("Phone", text: $viewModel.phone)
                        .textContentType(.telephoneNumber)
                        .textFieldStyle(InputTextFieldStyle(title: "Phone"))
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                        .textFieldStyle(InputTextFieldStyle(title: "Password"))
                    if viewModel.isRegistering {
                        TextField("", text: $viewModel.verificationCode)
                            .textContentType(.oneTimeCode)
                            .textFieldStyle(
                                InputTextFieldWithButtonStyle(
                                    title: "Verification Code") {
                                        Button {
                                            viewModel.sendVerificationCode()
                                        } label: {
                                            Group {
                                                if viewModel.isSendingVerificationCode {
                                                    ProgressView()
                                                        .controlSize(.small)
                                                } else {
                                                    Text("Send")
                                                }
                                            }
                                            .padding(.vertical, 6)
                                        }
                                        .disabled(viewModel.phone.isEmpty || viewModel.isSendingVerificationCode)
                            })
                    }
                }
                .padding(.bottom, 8)
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                    }
                    .keyboardShortcut(.cancelAction)
                    Spacer()
                        .frame(maxWidth: 40)
                    Button {
                        viewModel.submit()
                    } label: {
                        Group {
                            if viewModel.isSubmitting {
                                ProgressView()
                                    .controlSize(.small)
                            } else if !viewModel.isRegistering {
                                Text("Login")
                            } else {
                                Text("Register")
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
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
    LoginSheet()
        .background()
}
