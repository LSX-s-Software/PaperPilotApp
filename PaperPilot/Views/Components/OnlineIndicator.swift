//
//  OnlineIndicator.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/11/1.
//

import SwiftUI

struct OnlineIndicator: View {
    var loading: Bool
    var online: Bool
    var errorMsg: String?

    var body: some View {
        HStack(spacing: 6) {
            if loading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Circle()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(online ? .green : .yellow)
            }

            Group {
                if loading {
                    Text("Connecting...")
                } else if online && errorMsg == nil {
                    Text("Online")
                } else {
                    Text(errorMsg ?? String(localized: "Unknown error"))
                }
            }
            .fontWeight(.medium)
        }
        .padding(8)
        .background(.thickMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8)
        .animation(.default, value: loading)
    }
}

#Preview {
    VStack {
        OnlineIndicator(loading: true, online: false, errorMsg: nil)

        OnlineIndicator(loading: false, online: true, errorMsg: nil)

        OnlineIndicator(loading: false, online: false, errorMsg: nil)
    }
    .padding()
    .background()
}
