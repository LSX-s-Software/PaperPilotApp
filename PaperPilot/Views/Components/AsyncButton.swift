//
//  AsyncButton.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/19.
//

import SwiftUI

struct AsyncButton: View {
    let title: LocalizedStringKey
    let role: ButtonRole?
    let controlSize: ControlSize
    let disabled: Bool
    let action: () async -> Void
    
    @State private var loading = false
    
    init(_ title: LocalizedStringKey,
         role: ButtonRole? = nil,
         controlSize: ControlSize = .mini,
         disabled: Bool = false,
         action: @escaping () async -> Void) {
        self.title = title
        self.role = role
        self.controlSize = controlSize
        self.disabled = disabled
        self.action = action
        self.loading = loading
    }
    
    var body: some View {
        Button(role: role) {
            loading = true
            Task {
                await action()
                loading = false
            }
        } label: {
            Text(title)
                .opacity(loading ? 0 : 1)
        }
        .overlay {
            if loading {
                ProgressView()
                    .controlSize(controlSize)
            }
        }
        .disabled(loading || disabled)
    }
}

#Preview {
    AsyncButton("Submit") {
        try? await Task.sleep(for: .seconds(1))
    }
    .padding()
}
