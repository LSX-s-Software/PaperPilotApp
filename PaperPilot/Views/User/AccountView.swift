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
                    AsyncImage(url: URL(string: avatar ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                            .controlSize(.small)
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
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
