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
        #if os(macOS)
        switch controlSize {
        case .mini, .small:
                .mini
        case .regular, .large, .extraLarge:
                .small
        @unknown default:
                .regular
        }
        #else
        return controlSize
        #endif
    }
    let action: () async -> Void

    @State private var hasTaskFinished = true
    @Binding var loading: Bool
    var done: Bool {
        !loading && hasTaskFinished
    }

    init(role: ButtonRole? = nil,
         loading: Binding<Bool> = .constant(false),
         action: @escaping () async -> Void,
         @ViewBuilder label: @escaping () -> Content
    ) {
        self.title = label
        self.role = role
        self.action = action
        self._loading = loading
    }

    init(_ title: LocalizedStringKey,
         role: ButtonRole? = nil,
         loading: Binding<Bool> = .constant(false),
         action: @escaping () async -> Void
    ) where Content == Text {
        self.init(role: role, loading: loading, action: action) {
            Text(title)
        }
    }

    var body: some View {
        Button(role: role) {
            hasTaskFinished = false
            Task {
                await action()
                hasTaskFinished = true
            }
        } label: {
            title()
                .opacity(done ? 1 : 0)
        }
        .overlay {
            if !done {
                ProgressView()
                    .controlSize(progressSize)
            }
        }
        .disabled(!done)
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
