//
//  GeneralSettingsView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/22.
//

import SwiftUI

struct GeneralSettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isShowingDeleteDataConfirm = false

    var body: some View {
        Form {
            Section("Data") {
                Button("Delete All Data") {
                    isShowingDeleteDataConfirm.toggle()
                }
                .confirmationDialog(
                    "Are you sure to delete all data?",
                    isPresented: $isShowingDeleteDataConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) {
                        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                            try? FileManager.default.removeItem(at: url)
                            modelContext.container.deleteAllData()
                        }
                    }
                } message: {
                    Text("This action cannot be undone.")
                }
                .dialogSeverity(.critical)
            }
        }
        .padding()
    }
}

#Preview {
    GeneralSettingsView()
}
