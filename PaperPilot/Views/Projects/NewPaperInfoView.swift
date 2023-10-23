//
//  NewPaperInfoView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/10.
//

import SwiftUI
import GRPC

struct NewPaperInfoView: View {
    @Bindable var project: Project
    @Bindable var paper: Paper
    @Binding var shouldClose: Bool
    @State private var hasError = false
    @State private var errorMsg: String?

    var body: some View {
        ImageTitleForm("Supplement Information", systemImage: "doc.badge.ellipsis") {
            Section("Required Info") {
                TextField("Title", text: $paper.title)
            }
            
            Section("Optional Info") {
                TextField("Publication Year", text: Binding {
                    paper.publicationYear ?? ""
                } set: {
                    paper.publicationYear = $0.isEmpty ? nil : $0
                })
                TextField("Publication", text: Binding {
                    paper.publication ?? ""
                } set: {
                    paper.publication = $0.isEmpty ? nil : $0
                })
                TextField("Volume", text: Binding { paper.volume ?? "" } set: { paper.volume = $0.isEmpty ? nil : $0 })
                TextField("Issue", text: Binding { paper.issue ?? "" } set: { paper.issue = $0.isEmpty ? nil : $0 })
                TextField("Pages", text: Binding { paper.pages ?? "" } set: { paper.pages = $0.isEmpty ? nil : $0 })
                TextField("DOI", text: Binding { paper.doi ?? "" } set: { paper.doi = $0.isEmpty ? nil : $0 })
                TextField("Abstract", text: Binding { paper.abstract ?? "" } set: { paper.abstract = $0.isEmpty ? nil : $0 })
            }
        } onDismiss: {
            // rollback
            if let remoteId = paper.remoteId {
                Task {
                    do {
                        _ = try await API.shared.paper.deletePaper(.with { $0.id = remoteId })
                    } catch {
                        print(error)
                    }
                }
            }
        }
        .alert("Failed to Add Paper", isPresented: $hasError) {} message: {
            Text(errorMsg ?? String(localized: "Unknown error"))
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                AsyncButton("Add") {
                    if paper.remoteId != nil {
                        do {
                            _ = try await API.shared.paper.updatePaper(paper.paperDetail)
                        } catch let error as GRPCStatus {
                            hasError = true
                            errorMsg = error.message
                            return
                        } catch {
                            hasError = true
                            errorMsg = error.localizedDescription
                            return
                        }
                    }
                    if paper.project == nil {
                        project.papers.append(paper)
                    }
                    shouldClose = true
                }
                .keyboardShortcut(.defaultAction)
                .disabled(paper.title.isEmpty)
            }
        }
    }
}

#Preview {
    NewPaperInfoView(project: ModelData.project1, paper: ModelData.paper1, shouldClose: .constant(false))
        .modelContainer(previewContainer)
}
