//
//  SharedNoteView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/28.
//

import SwiftUI
import ShareKit
import Throttler
import Combine
import SwiftDown

struct SharedNoteView: View {
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var paper: Paper

    @AppStorage(AppStorageKey.Reader.noteFontSize.rawValue)
    private var fontSize: Double = 16

    @State private var loading = true
    @State private var shareDocument: ShareDocument<SharedNote>?
    @State private var errorMsg: String?
    @State private var bag = Set<AnyCancellable>()
    @State private var sharedNote = SharedNote()
    let dateFormatter = ISO8601DateFormatter()
    var themeName: String {
        colorScheme == .light ? "GithubTheme" : "GithubDarkTheme"
    }

    var body: some View {
        SwiftDownEditor(text: Binding { sharedNote.content } set: { handleModifyNote($0) })
            .insetsSize(6)
            .theme(Theme(themePath: Bundle.main.path(forResource: themeName, ofType: "json")!))
            .font(.system(size: CGFloat(fontSize)))
            .overlay(alignment: .bottom) {
                if paper.remoteId != nil {
                    OnlineIndicator(loading: loading, online: shareDocument != nil, errorMsg: errorMsg)
                        .offset(y: -20)
                }
            }
            .task(id: paper.id) {
                sharedNote.content = paper.note
                sharedNote.timestamp = paper.noteUpdateTime.ISO8601Format()
                guard let id = paper.remoteId else { return }
                await ShareCoordinator.shared.connect()
                do {
                    shareDocument = try await ShareCoordinator.shared.getDocument(id, in: .notes)
                    if await shareDocument!.notCreated {
                        try await shareDocument!.create(SharedNote())
                    }
                    await shareDocument!.value
                        .compactMap { $0 }
                        .receive(on: RunLoop.main)
                        .sink { newNote in
                            let newDate = dateFormatter.date(from: newNote.timestamp) ?? Date.now
                            let oldDate = dateFormatter.date(from: sharedNote.timestamp) ?? Date.distantPast
                            if newDate > oldDate {
                                sharedNote = newNote
                            } else {
                                handleModifyNote(sharedNote.content)
                            }
                        }
                        .store(in: &bag)
                } catch {
                    print("init error:", error)
                    errorMsg = error.localizedDescription
                }
                loading = false
            }
    }

    func handleModifyNote(_ newNote: String) {
        sharedNote.content = newNote
        let updateTime = Date.now
        debounce(.seconds(5)) {
            Task {
                await ModelService.shared.updatePaper(paper, note: newNote, noteUpdateTime: updateTime)
            }
        }
        if paper.remoteId == nil { return }
        Task {
            do {
                try await shareDocument?.change {
                    try $0.content.set(newNote)
                    try $0.timestamp.set(dateFormatter.string(from: updateTime))
                }
            } catch {
                print("update error:", error)
                errorMsg = error.localizedDescription
            }
        }
    }
}

#Preview {
    SharedNoteView(paper: ModelData.paper1)
}
