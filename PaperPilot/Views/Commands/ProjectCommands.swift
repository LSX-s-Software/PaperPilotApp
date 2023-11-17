//
//  ProjectCommands.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/27.
//

import SwiftUI

struct ProjectCommands: Commands {
    @Environment(AppState.self) private var appState

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Menu("New") {
                Button("Project", systemImage: "folder.badge.plus") {
                    appState.isCreatingProject = true
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }

        CommandMenu("Project") {
            Button("Join Project", systemImage: "folder.badge.person.crop") {
                appState.isShowingJoinProjectView = true
            }
            .keyboardShortcut("j")

            Divider()

            Button("Share Project", systemImage: "square.and.arrow.up") {
                appState.isSharingProject = true
            }
            .keyboardShortcut("s")

            Button("Edit Project", systemImage: "pencil") {
                appState.isEditingProject = true
            }
#if os(macOS)
            .keyboardShortcut("e")
#else
            .keyboardShortcut("e", modifiers: [.command, .shift])
#endif

            Divider()

            Button("Add Paper", systemImage: "plus") {
                appState.isAddingPaper = true
            }
            .keyboardShortcut("n")
        }
    }
}
