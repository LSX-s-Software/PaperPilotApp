//
//  SharedNoteView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/28.
//

import SwiftUI
import ShareKit
import Combine

struct SharedNote: Codable {
    var content = ""
}

struct SharedNoteView: View {
    @Bindable var paper: Paper

    @AppStorage(AppStorageKey.Reader.noteFontSize.rawValue)
    private var fontSize: Double = 16

    @State private var loading = true
    @State private var shareDocument: ShareDocument<SharedNote>?
    @State private var errorMsg: String?
    @State private var bag = Set<AnyCancellable>()
    @State private var sharedNote = SharedNote()

    var body: some View {
        TextEditor(text: Binding { sharedNote.content } set: { handleModifyNote($0) })
            .font(.system(size: CGFloat(fontSize)))
            .overlay(alignment: .bottom) {
                if paper.remoteId != nil {
                    HStack(spacing: 6) {
                        if loading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Circle()
                                .frame(width: 12, height: 12)
                                .foregroundStyle(shareDocument != nil && errorMsg == nil ? .green : .yellow)
                        }

                        Group {
                            if loading {
                                Text("Connecting...")
                            } else if shareDocument != nil && errorMsg == nil {
                                Text("Online")
                            } else {
                                Text(errorMsg ?? String(localized: "Unknown error"))
                            }
                        }
                        .fontWeight(.medium)
                    }
                    .padding(8)
                    .background(.thickMaterial)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 8)
                    .offset(y: -20)
                    .animation(.default, value: loading)
                }
            }
            .task(id: paper.id) {
                sharedNote.content = paper.note
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
                        .assign(to: \.sharedNote, on: self)
                        .store(in: &bag)
                } catch {
                    print("init error:", error)
                    errorMsg = error.localizedDescription
                }
                loading = false
            }
    }

    func handleModifyNote(_ newNote: String) {
        Task {
            if paper.remoteId == nil {
                await ModelService.shared.updatePaper(paper, note: newNote)
                sharedNote.content = newNote
                return
            }
            do {
                try await shareDocument?.change {
                    try $0.content.set(newNote)
                }
                await ModelService.shared.updatePaper(paper, note: newNote)
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
