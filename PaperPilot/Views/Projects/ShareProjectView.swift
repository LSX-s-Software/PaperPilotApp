//
//  ShareProjectView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/22.
//

import SwiftUI
import GRPC

struct ShareProjectView: View {
    @EnvironmentObject private var navigationContext: NavigationContext

    @Bindable var project: Project

    @AppStorage(AppStorageKey.User.username.rawValue)
    private var username: String?

    @StateObject private var downloadVM = DownloadViewModel()
    @State private var promptMsg: String?
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
                GroupBox("Members") {
                    LazyVGrid(columns: [GridItem](repeating: GridItem(), count: 6)) {
                        ForEach(project.members) { member in
                            AvatarView(url: URL(string: member.avatar), size: 36)
#if os(macOS)
                                .toolTip(member.username)
#endif
                        }
                    }
                    .frame(minHeight: 36)
                }

                Group {
                    GroupBox("Invitation Code") {
                        Text(project.invitationCode ?? String(localized: "No invitation code"))
                            .lineLimit(1)
                            .textSelection(.enabled)
                            .frame(minWidth: 256, alignment: .leading)
                            .fixedSize()
                    }

                    HStack {
                        Button("Copy Invitation", systemImage: "doc.on.doc") {
                            if let inviteCode = project.invitationCode {
                                setPasteboard(inviteCode)
                            }
                        }

                        ShareLink(
                            "Send Invitation",
                            item: URL(string: "https://paperpilot.ziqiang.net.cn/invite.html?invitation=\(project.invitationCode ?? "")")!,
                            subject: Text(project.name),
                            message: Text("\(username ?? String(localized: "I")) invites you to join the project \"\(project.name)\" on Paper Pilot.")
                        )
                    }
                }
                .disabled(project.invitationCode == nil || project.invitationCode!.isEmpty)
            } else {
                Label("Cannot invite others to join local projects.", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)

                AsyncButton("Convert to remote project") {
                    await uploadProject()
                }

                if downloading {
                    Group {
                        if let progress = downloadProgress {
                            ProgressView(value: progress.fractionCompleted)
                                .id(downloadVM.downloadProgress)
                        } else {
                            ProgressView()
                        }
                    }
                    .progressViewStyle(.linear)
                    .padding(.horizontal)
                    .frame(width: 200)
                }

                if let prompt = promptMsg {
                    Text(prompt)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    func uploadProject() async {
        promptMsg = nil
        do {
            downloading = true
            downloadProgress = Progress(totalUnitCount: Int64(project.papers.count))
            for paper in project.papers {
                promptMsg = String(localized: "Downloading: \(paper.title)")
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
            promptMsg = String(localized: "Converting project...")
            try await project.upload()
        } catch {
            promptMsg = String(localized: "Convert failed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ShareProjectView(project: ModelData.project1)
        .modelContainer(previewContainer)
        .fixedSize()
}
