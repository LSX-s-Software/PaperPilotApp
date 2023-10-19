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
    
    var body: some View {
        ImageTitleDialog(
            "Join Project",
            subtitle: "Use invitation code to join project",
            systemImage: "folder.fill.badge.person.crop"
        ) {
            TextField("Invitation Code", text: $invitationCode)
                .textFieldStyle(.roundedBorder)
            Text("You can get invitation code from any member of the project.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                AsyncButton("Join", disabled: invitationCode.isEmpty) {
                    do {
                        let result = try await API.shared.project.joinProject(.with {
                            $0.inviteCode = invitationCode
                        })
                        let newProject = Project(remoteId: result.id,
                                                 name: result.name,
                                                 desc: result.description_p,
                                                 invitationCode: result.inviteCode)
                        modelContext.insert(newProject)
                    } catch let error as GRPCStatus {
                        hasError = true
                        errorMsg = error.message
                    } catch {
                        hasError = true
                        errorMsg = error.localizedDescription
                    }
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
