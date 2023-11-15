//
//  PaperCommands.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/27.
//

import SwiftUI

struct PaperCommands: Commands {
    @Environment(AppState.self) private var appState
    @FocusedBinding(\.selectedPaper) private var selectedPaper: Paper?

    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Group {
                if let selectedPaper = selectedPaper, appState.findingPaper.contains(selectedPaper.id) {
                    Button("Stop Finding", systemImage: "magnifyingglass") {
                        appState.findingPaper.remove(selectedPaper.id)
                    }
                } else {
                    Button("Find in PDF", systemImage: "magnifyingglass") {
                        appState.findingPaper.insert(selectedPaper!.id)
                    }
                }
            }
#if os(macOS)
            .keyboardShortcut("f")
#else
            .keyboardShortcut("f", modifiers: [.command, .option])
#endif
            .disabled(selectedPaper == nil)
        }
        
        CommandMenu("Paper") {
            Menu("Copy Information", systemImage: "doc.on.doc") {
                ForEach(Paper.copiableProperties, id: \.0) { name, keypath in
                    Button(LocalizedStringKey(name)) {
                        if let paper = selectedPaper, let value = paper[keyPath: keypath] as? String {
                            setPasteboard(value)
                        }
                    }
                    .disabled(selectedPaper == nil || !(selectedPaper![keyPath: keypath] is String))
                }
            }

            Divider()

            Button("Mark as Unread", systemImage: "circle") {
                selectedPaper?.read = false
            }
            .disabled(selectedPaper == nil)
        }
    }
}
