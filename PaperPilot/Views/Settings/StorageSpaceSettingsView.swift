//
//  StorageSpaceSettingsView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/22.
//

import SwiftUI

struct StorageSpaceSettingsView: View {
    @State private var totalUsedSpace: UInt64?
    @State private var totalUsedSpaceError: String?
    @State private var isShowingClearFileConfirm = false

    var baseDir: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    var body: some View {
        Form {
            Section("Local Files") {
                if let baseDir = baseDir {
                    HStack {
                        TextField("Location:", text: .constant(baseDir.path(percentEncoded: false)))
                        Button("Show in Finder") {
                            NSWorkspace.shared.open(baseDir)
                        }
                    }

                    LabeledContent("Total Used Space:") {
                        if let totalUsedSpace = totalUsedSpace {
                            Text(ByteCountFormatter().string(fromByteCount: Int64(totalUsedSpace)))
                                .foregroundColor(.secondary)
                        } else if let errorMsg = totalUsedSpaceError {
                            VStack(alignment: .leading) {
                                Label("Failed to calculate", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(errorMsg)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    .task {
                        calcUsedSpace()
                    }

                    Button("Delete Projects' Local Files", role: .destructive) {
                        isShowingClearFileConfirm.toggle()
                    }
                    .confirmationDialog(
                        "Are you sure to delete all projects' local file?",
                        isPresented: $isShowingClearFileConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Delete", role: .destructive) {
                            let url = baseDir.appending(path: FilePath.projectDirectory.rawValue)
                            try? FileManager.default.removeItem(at: url)
                            calcUsedSpace()
                        }
                    } message: {
                        Text("Will delete all imported/downloaded PDFs. ") + Text("This action cannot be undone.")
                    }
                    .dialogSeverity(.critical)
                }
            }
        }
        .padding()
    }

    func calcUsedSpace() {
        if let baseDir = baseDir {
            do {
                totalUsedSpace = try FileManager.default.totalSize(atPath: baseDir.path(percentEncoded: false))
            } catch {
                totalUsedSpaceError = error.localizedDescription
            }
        }
    }
}

#Preview {
    StorageSpaceSettingsView()
}
