//
//  AsyncButton.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/19.
//

import SwiftUI

struct AsyncButton<Content: View>: View {
    @Environment(\.controlSize) private var controlSize

    let title: () -> Content
    let role: ButtonRole?
    var progressSize: ControlSize {
        switch controlSize {
        case .mini, .small:
                .mini
        case .regular, .large, .extraLarge:
                .small
        @unknown default:
                .regular
        }
    }
    let disabled: Bool
    let action: () async -> Void
    
    @State private var loading = false
    
    init(role: ButtonRole? = nil,
         disabled: Bool = false,
         action: @escaping () async -> Void,
         @ViewBuilder label: @escaping () -> Content) {
        self.title = label
        self.role = role
        self.disabled = disabled
        self.action = action
    }
    
    init(_ title: LocalizedStringKey,
         role: ButtonRole? = nil,
         disabled: Bool = false,
         action: @escaping () async -> Void) where Content == Text {
        self.init(role: role, disabled: disabled, action: action) {
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
                    .controlSize(progressSize)
            }
        }
        .disabled(loading || disabled)
    }
}

#Preview {
    VStack {
        AsyncButton("Mini") {
            try? await Task.sleep(for: .seconds(1))
        }
        .controlSize(.mini)

        AsyncButton("Small") {
            try? await Task.sleep(for: .seconds(1))
        }
        .controlSize(.small)

        AsyncButton("Regular") {
            try? await Task.sleep(for: .seconds(1))
        }
        .controlSize(.regular)

        AsyncButton("Large") {
            try? await Task.sleep(for: .seconds(1))
        }
        .controlSize(.large)

        AsyncButton("Extra Large") {
            try? await Task.sleep(for: .seconds(1))
        }
        .controlSize(.extraLarge)
    }
    .padding()
}
