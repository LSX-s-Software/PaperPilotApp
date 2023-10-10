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
    
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                    .symbolRenderingMode(.hierarchical)
                Text("Login")
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .padding(.bottom, 1)
                Text("Login to collaborate with your teammates")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
                    .frame(height: 24)
                Group {
                    VStack(alignment: .leading) {
                        Text("Phone")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Phone", text: $phone)
                            .textFieldStyle(.plain)
#if !os(macOS)
                            .textContentType(.telephoneNumber)
#endif
                            .padding(8)
                            .background()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.bottom, 4)
                    VStack(alignment: .leading) {
                        Text("Password")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        SecureField("Password", text: $password)
                            .textFieldStyle(.plain)
#if !os(macOS)
                            .textContentType(.password)
#endif
                            .padding(8)
                            .background()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .frame(width: 300)
                Spacer()
                    .frame(height: 24)
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
                        
                    } label: {
                        Text("Login")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
}

#Preview {
    LoginSheet()
}
