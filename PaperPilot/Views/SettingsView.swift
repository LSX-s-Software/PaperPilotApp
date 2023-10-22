//
//  SettingsView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/22.
//

import SwiftUI

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general
        case file
    }

    @Environment(\.modelContext) private var modelContext

    @State private var showingClearFileConfirm = false

    var body: some View {
        TabView {
            Form {
                Section("Data") {
                    Button("Delete All Projects") {

                    }
                }
            }
            .padding()
            .tabItem { Label("General", systemImage: "gearshape") }
            .tag(Tabs.general)

            Form {
                Section("Local Files") {
                    Button("Delete All Project Files", role: .destructive) {
                        showingClearFileConfirm.toggle()
                    }
                    .confirmationDialog(
                        "Are you sure you want to delete all project files?",
                        isPresented: $showingClearFileConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Delete", role: .destructive) {
                            try? FileManager.default.removeItem(at: FileManager.default.url(for: .documentDirectory,
                                                                                            in: .userDomainMask,
                                                                                            appropriateFor: nil,
                                                                                            create: false)
                                .appending(path: FilePath.projectDirectory.rawValue))
                        }
                    } message: {
                        Text("This action cannot be undone.")
                    }
                }
            }
            .padding()
            .tabItem { Label("Storage Space", systemImage: "internaldrive") }
            .tag(Tabs.general)
        }
    }
}

#Preview {
    SettingsView()
}
