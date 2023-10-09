//
//  AccountView.swift
//  PaperPilot
//
//  Created by mike on 2023/10/9.
//

import SwiftUI

struct AccountView: View {
    @Binding var isShowingAccountView: Bool
    var username = "User"
    var email = "user@example.com"

    var body: some View {
        VStack {
            HStack(alignment: .bottom) {
                Text("Account")
                    .font(.largeTitle)

                Spacer()

                Button("Done") {
                    isShowingAccountView = false
                }
                .buttonStyle(.borderless)
            }

            Divider()

            HStack {
                Image(systemName: "person.crop.circle")
                    .resizable(resizingMode: .stretch)
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading) {
                    Text(verbatim: username)
                        .font(.headline)
                    Text(verbatim: email)
                }
            }
        }.padding(.all)
    }
}

#Preview {
    AccountView(isShowingAccountView: Binding(get: {true}, set: {_ in }))
}
