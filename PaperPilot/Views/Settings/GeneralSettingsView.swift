//
//  GeneralSettingsView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/22.
//

import SwiftUI

struct GeneralSettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage(AppStorageKey.Reader.noteFontSize.rawValue)
    private var noteFontSize: Double = 16

    @State private var isShowingDeleteDataConfirm = false

    var body: some View {
        Form {
            Section("Font Size") {
                LabeledContent("Note") {
                    HStack {
                        Slider(value: $noteFontSize, in: 12...24, step: 1) {
                            EmptyView()
                        } minimumValueLabel: {
                            Label("Smaller", systemImage: "textformat.size.smaller")
                        } maximumValueLabel: {
                            Label("Larger", systemImage: "textformat.size.larger")
                        }
                        .labelStyle(.iconOnly)
                        .frame(maxWidth: 250)

                        Button("Reset") {
                            noteFontSize = 16
                        }
                        .controlSize(.small)
                    }
                }
            }

            Divider()

            Section("Data") {
                Button("Delete All Data", role: .destructive) {
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
#if os(macOS)
                .dialogSeverity(.critical)
#endif
            }
        }
        .padding()
    }
}

#Preview {
    GeneralSettingsView()
        .frame(width: 500)
}
