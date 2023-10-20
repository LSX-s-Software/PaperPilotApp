//
//  AccountView.swift
//  PaperPilot
//
//  Created by mike on 2023/10/9.
//

import SwiftUI

struct AccountView: View {
    @Environment(\.dismiss) var dismiss

    @State var isShowingLogoutConfirmation = false
    @State var isEditing = false

    @AppStorage(AppStorageKey.User.phone.rawValue)
    private var phone: String?
    @AppStorage(AppStorageKey.User.accessToken.rawValue)
    private var accessToken: String?
    @AppStorage(AppStorageKey.User.avatar.rawValue)
    private var avatar: String?
    @AppStorage(AppStorageKey.User.username.rawValue)
    private var username: String?

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    AvatarView()
                    VStack(alignment: .leading) {
                        Text(username ?? "Logged Out")
                            .font(.headline)
                        Text(phone ?? "Logged Out")
                    }

                    Spacer(minLength: 50)

                    Button("Logout") {
                        isShowingLogoutConfirmation.toggle()
                    }
                    .confirmationDialog("Are you sure you want to log out?", isPresented: $isShowingLogoutConfirmation) {
                        Button("Confirm", role: .destructive, action: logOut)
                    }
                }
            }
            .padding()
            .navigationTitle("Account")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem {
                    if !isEditing {
                        Button("Edit") {
                            isEditing = true
                        }
                    } else {
                        Button("Cancel") {
                            isEditing = false
                        }
                    }
                }
            }
        }
    }

    func logOut() {
        dismiss()
        self.accessToken = nil
        self.username = nil
    }
}

#Preview {
    AccountView()
}
