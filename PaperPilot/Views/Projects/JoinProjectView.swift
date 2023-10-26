//
//  JoinProjectView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/19.
//

import SwiftUI
import GRPC

struct JoinProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var invitationCode = ""
    @State private var hasError = false
    @State private var errorMsg: String?
    
    init() {}
    
    init(invitationURL: URL) {
        if let components = URLComponents(url: invitationURL, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems,
           let code = queryItems.first(where: { $0.name == AppURLScheme.QueryKeys.Project.invitation.rawValue })?.value {
            self._invitationCode = State(initialValue: code)
        }
    }
    
    var body: some View {
        NavigationStack {
            ImageTitleDialog(
                "Join Project",
                subtitle: "Use invitation code to join project",
                systemImage: "folder.fill.badge.person.crop"
            ) {
                VStack(alignment: .leading) {
                    HStack {
                        TextField("Invitation Code", text: $invitationCode)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1)
                        PasteButton(payloadType: String.self) { payload in
                            if let code = payload.first {
                                invitationCode = code
                            }
                        }
                    }
                    
                    Text("You can get invitation code from any member of the project.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    AsyncButton("Join") {
                        do {
                            let result = try await API.shared.project.joinProject(.with {
                                $0.inviteCode = invitationCode
                            })
                            let newProject = Project(remoteId: result.id,
                                                     name: result.name,
                                                     desc: result.description_p,
                                                     invitationCode: result.inviteCode,
                                                     isOwner: false)
                            modelContext.insert(newProject)
                            newProject.members = result.members.map { member in
                                let user = User(from: member)
                                modelContext.insert(user)
                                return user
                            }
                            dismiss()
                        } catch let error as GRPCStatus {
                            hasError = true
                            errorMsg = error.message
                        } catch {
                            hasError = true
                            errorMsg = error.localizedDescription
                        }
                    }
                    .disabled(invitationCode.isEmpty)
                }
            }
        }
        .alert("Failed to join project", isPresented: $hasError) {} message: {
            Text(errorMsg ?? String(localized: "Unknown error"))
        }
    }
}

#Preview {
    JoinProjectView()
}
