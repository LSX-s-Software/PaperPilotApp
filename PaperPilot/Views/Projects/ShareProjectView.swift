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
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Cannot invite others to join local projects.")
                }
                .foregroundStyle(.red)

                AsyncButton("Convert to remote project") {
                    do {
                        try await project.upload()
                    } catch {
                        print(error)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    ShareProjectView(project: ModelData.project1)
}
