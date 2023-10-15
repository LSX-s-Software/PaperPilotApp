//
//  AccountView.swift
//  PaperPilot
//
//  Created by mike on 2023/10/9.
//

import SwiftUI

struct AccountView: View {
    @Environment(\.dismiss) var dismiss
    
    @AppStorage(AppStorageKey.User.loggedIn.rawValue)
    private var loggedIn = false
    
    @State var isShowingLogoutConfirmation = false
    @AppStorage(AppStorageKey.User.phone.rawValue)
    private var phone: String?
    @AppStorage(AppStorageKey.User.avatar.rawValue)
    private var avatar: String?
    @AppStorage(AppStorageKey.User.username.rawValue)
    private var username: String?

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    AsyncImage(url: URL(string: avatar!)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 40, height: 40)
                    VStack(alignment: .leading) {
                        Text(username!)
                            .font(.headline)
                        Text(phone!)
                    }
                    
                    Spacer(minLength: 50)
                    
                    Button("Logout") {
                        isShowingLogoutConfirmation.toggle()
                    }
                    .confirmationDialog("Are you sure to logout?", isPresented: $isShowingLogoutConfirmation) {
                        Button("Confirm", role: .destructive) {
                            loggedIn = false
                        }
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
}

#Preview {
    AccountView()
}
