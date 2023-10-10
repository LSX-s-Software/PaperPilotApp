//
//  AccountView.swift
//  PaperPilot
//
//  Created by mike on 2023/10/9.
//

import SwiftUI

struct AccountView: View {
    @Environment(\.dismiss) var dismiss
    
    var username = "User"
    var email = "user@example.com"

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
                    Spacer()
                    Button("Logout", role: .destructive) {
                        
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
