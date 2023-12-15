//
//  NewPaperInfoView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/10.
//

import SwiftUI
import GRPC
import OSLog
import SwiftyBibtex

private let logger = LoggerFactory.make(category: "NewPaperInfoView")

struct NewPaperInfoView: View {
    @Bindable var project: Project
    @Bindable var paper: Paper
    @Binding var shouldClose: Bool
    @State private var hasError = false
    @State private var errorMsg: String?
    @State private var bibtex = ""
    @State private var bibtexParsingError: String?

    var body: some View {
        NavigationStack {
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
                    TextField("Event", text: Binding { paper.event ?? "" } set: { paper.event = $0.isEmpty ? nil : $0 })
                    TextField("Volume", text: Binding { paper.volume ?? "" } set: { paper.volume = $0.isEmpty ? nil : $0 })
                    TextField("Issue", text: Binding { paper.issue ?? "" } set: { paper.issue = $0.isEmpty ? nil : $0 })
                    TextField("Pages", text: Binding { paper.pages ?? "" } set: { paper.pages = $0.isEmpty ? nil : $0 })
                    TextField("URL", text: Binding { paper.url ?? "" } set: { paper.url = $0.isEmpty ? nil : $0 })
                    TextField("DOI", text: Binding { paper.doi ?? "" } set: { paper.doi = $0.isEmpty ? nil : $0 })
                }

                Section("Or Update By BibTeX") {
                    TextEditor(text: $bibtex)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .frame(minWidth: 450, minHeight: 150)
                    HStack {
                        Button("Update", action: updatePaperByBibTeX)
                        if let errorMsg = bibtexParsingError {
                            Label(errorMsg, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
            } onDismiss: {
                // rollback
                Task {
                    do {
                        if let paper = await ModelService.shared.getPaper(id: paper.id) {
                            try await ModelService.shared.deletePaper(paper)
                        }
                    } catch {
                        logger.warning("Rollback failed: \(error)")
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
                        // Index in CoreSpotlight
                        SpotlightHelper.index(paper: paper)
                        shouldClose = true
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(paper.title.isEmpty)
                }
            }
        }
    }

    func updatePaperByBibTeX() {
        do {
            let result = try SwiftyBibtex.parse(bibtex)
            guard let publication = result.publications.first else {
                bibtexParsingError = String(localized: "No publication found.")
                return
            }
            switch publication {
            case let article as Article:
                paper.title = article.title
                paper.authors = article.author
                    .split(separator: " and ")
                    .map { $0.split(separator: ", ").reversed().joined(separator: " ") }
                paper.publication = article.journal
                paper.publicationYear = String(format: "%d", article.year)
                paper.pages = article.pages
            case let inproceedings as InProceedings:
                paper.title = inproceedings.title
                paper.authors = inproceedings.author
                    .split(separator: " and ")
                    .map { $0.split(separator: ", ").reversed().joined(separator: " ") }
                paper.publication = inproceedings.bookTitle
                paper.publicationYear = String(format: "%d", inproceedings.year)
                paper.pages = inproceedings.pages
                if let volume = inproceedings.volume { paper.volume = String(volume) }
            default:
                bibtexParsingError = String(localized: "Unsupported publication type.")
            }
        } catch {
            bibtexParsingError = error.localizedDescription
        }
    }
}

#Preview {
    NewPaperInfoView(project: ModelData.project1, paper: ModelData.paper1, shouldClose: .constant(false))
        .modelContainer(previewContainer)
}
