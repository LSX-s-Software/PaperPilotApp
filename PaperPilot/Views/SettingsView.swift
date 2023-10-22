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

    @State private var isShowingClearFileConfirm = false
    @State private var isShowingDeleteDataConfirm = false

    var body: some View {
        TabView {
            Form {
                Section("Data") {
                    Button("Delete All Data") {
                        isShowingDeleteDataConfirm.toggle()
                    }
                    .confirmationDialog(
                        "Are you sure you want to delete all data?",
                        isPresented: $isShowingDeleteDataConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Delete", role: .destructive) {
                            modelContext.container.deleteAllData()
                        }
                    } message: {
                        Text("This action cannot be undone.")
                    }
                }
            }
            .padding()
            .tabItem { Label("General", systemImage: "gearshape") }
            .tag(Tabs.general)

            Form {
                Section("Local Files") {
                    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
                        .appending(path: FilePath.projectDirectory.rawValue) {
                        HStack {
                            TextField("Location", text: .constant(dir.path()))
                            Button("Show in Finder") {
                                NSWorkspace.shared.open(dir)
                            }
                        }
                    }

                    Button("Delete All Project Files", role: .destructive) {
                        isShowingClearFileConfirm.toggle()
                    }
                    .confirmationDialog(
                        "Are you sure you want to delete all project files?",
                        isPresented: $isShowingClearFileConfirm,
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
        .frame(width: 500)
}
