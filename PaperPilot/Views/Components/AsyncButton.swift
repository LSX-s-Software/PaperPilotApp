//
//  AsyncButton.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/19.
//

import SwiftUI

struct AsyncButton<Content: View>: View {
    let title: () -> Content
    let role: ButtonRole?
    let controlSize: ControlSize
    let disabled: Bool
    let action: () async -> Void
    
    @State private var loading = false
    
    init(role: ButtonRole? = nil,
         controlSize: ControlSize = .mini,
         disabled: Bool = false,
         action: @escaping () async -> Void,
         @ViewBuilder label: @escaping () -> Content) {
        self.title = label
        self.role = role
        self.controlSize = controlSize
        self.disabled = disabled
        self.action = action
    }
    
    init(_ title: LocalizedStringKey,
         role: ButtonRole? = nil,
         controlSize: ControlSize = .mini,
         disabled: Bool = false,
         action: @escaping () async -> Void) where Content == Text {
        self.init(
            role: role,
            controlSize: controlSize,
            disabled: disabled,
            action: action
        ) {
            Text(title)
        }
    }
    
    var body: some View {
        Button(role: role) {
            loading = true
            Task {
                await action()
                loading = false
            }
        } label: {
            title()
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
