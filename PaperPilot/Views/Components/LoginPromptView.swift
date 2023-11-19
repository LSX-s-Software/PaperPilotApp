//
//  LoginPromptView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/11/19.
//

import SwiftUI

struct LoginPromptView: View {
    @State private var isShowingLoginSheet = false

    var body: some View {
        ContentUnavailableView {
            Label("Feature Unavailable.", systemImage: "person.crop.circle.fill.badge.exclamationmark")
        } description: {
            Text("You need to login to use this feature.")
        } actions: {
            Button("Login") {
                isShowingLoginSheet.toggle()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
        .sheet(isPresented: $isShowingLoginSheet) {
            AccountView()
        }
    }
}

#Preview {
    LoginPromptView()
}

#Preview {
    LoginPromptView()
        .frame(width: 300)
}
