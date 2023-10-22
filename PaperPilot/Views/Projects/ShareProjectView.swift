//
//  ShareProjectView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/22.
//

import SwiftUI

struct ShareProjectView: View {
    @Bindable var project: Project

    @AppStorage(AppStorageKey.User.username.rawValue)
    private var username: String?

    @StateObject private var downloadVM = DownloadViewModel()
    @State private var errorMsg: String?
    @State private var downloading = false
    @State private var downloadProgress: Progress?

    var body: some View {
        VStack {
            Image(systemName: "person.3.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.title)
                .foregroundStyle(Color.accentColor)
            Text("Invite Others")
                .font(.title2)
                .fontWeight(.medium)

            if project.remoteId != nil {
                Group {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Invitation Code")
                            .font(.caption)
                        HStack {
                            TextField("Invitation Code", text: .constant(project.invitationCode ?? ""))
                                .textFieldStyle(.roundedBorder)
                                .disabled(true)
                                .frame(minWidth: 100)
                            Button("Copy") {
                                if let inviteCode = project.invitationCode {
                                    setPasteboard(inviteCode)
                                }
                            }
                        }
                    }
                    ShareLink(
                        "Send Invitation",
                        item: URL(string: "https://paperpilot.ziqiang.net.cn/invite.html?invitation=\(project.invitationCode ?? "")")!,
                        subject: Text(project.name),
                        message: Text("\(username ?? String(localized: "I")) invites you to join the project \"\(project.name)\" on Paper Pilot.")
                    )
                }
                .disabled(project.invitationCode == nil || project.invitationCode!.isEmpty)
            } else {
                Label("Cannot invite others to join local projects.", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)

                AsyncButton("Convert to remote project") {
                    await uploadProject()
                }

                Group {
                    if downloading {
                        Group {
                            if let progress = downloadProgress {
                                ProgressView(value: progress.fractionCompleted)
                            } else {
                                ProgressView()
                            }
                        }
                        .progressViewStyle(.linear)
                        .padding(.horizontal)
                        .frame(width: 200)
                        Text("Downloading PDF...")
                    }

                    if let errorMsg = errorMsg {
                        Text("Convert failed: \(errorMsg)")
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    func uploadProject() async {
        errorMsg = nil
        do {
            downloading = true
            downloadProgress = Progress(totalUnitCount: Int64(project.papers.count))
            for paper in project.papers {
                if let localFile = paper.localFile,
                   FileManager.default.isReadableFile(atPath: localFile.path()) {
                    downloadProgress?.completedUnitCount += 1
                    continue
                }
                if let urlStr = paper.file, let url = URL(string: urlStr) {
                    let localURL = try await downloadVM.downloadFile(from: url, parentProgress: downloadProgress)
                    let savedURL = try FilePath.paperDirectory(for: paper, create: true)
                        .appending(path: url.lastPathComponent)
                    try FileManager.default.moveItem(at: localURL, to: savedURL)
                    paper.localFile = savedURL
                } else {
                    downloadProgress?.completedUnitCount += 1
                }
            }
            downloading = false
            try await project.upload()
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}

#Preview {
    ShareProjectView(project: ModelData.project1)
}
