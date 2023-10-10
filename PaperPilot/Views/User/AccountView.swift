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
    
    @State var username = "User"
    @State var email = "user@example.com"
    @State var isShowingLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading) {
                        Text(username)
                            .font(.headline)
                        Text(email)
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
