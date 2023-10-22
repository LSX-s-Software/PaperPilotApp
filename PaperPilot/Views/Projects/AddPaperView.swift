//
//  AddPaperView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/10.
//

import SwiftUI

struct AddPaperView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var project: Project
    @State private var newPaper = Paper(title: "")
    @State private var filePath: URL?
    @State private var isImporting = false
    @State private var shouldGoNext = false
    @State private var shouldClose = false
    @State private var hasError = false
    @State private var errorMsg: String?

    var body: some View {
        NavigationStack {
            ImageTitleDialog("Add Paper", systemImage: "doc.fill.badge.plus") {
                VStack {
                    NavigationLink {
                        AddPaperByURLView(project: project, shouldClose: $shouldClose)
                    } label: {
                        HStack {
                            Image(systemName: "link")
                                .font(.system(size: 24))
                            VStack(alignment: .leading) {
                                Text("From URL/DOI")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                Text("Add paper from a URL or DOI")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Button {
                        isImporting = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.arrow.up")
                                .font(.system(size: 24))
                            VStack(alignment: .leading) {
                                Text("From file")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                Text("Add paper from local file")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .fileImporter(
                        isPresented: $isImporting,
                        allowedContentTypes: [.pdf],
                        onCompletion: handleImportFile
                    )
                    .fileDialogMessage("Select a PDF file to import")
                    .fileDialogConfirmationLabel("Import")
                    .alert("Failed to import this file", isPresented: $hasError) {} message: {
                        Text(errorMsg ?? String(localized: "Unknown error"))
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .navigationDestination(isPresented: $shouldGoNext) {
                NewPaperInfoView(project: project, paper: newPaper, shouldClose: $shouldClose)
            }
        }
        .onChange(of: shouldClose) {
            if shouldClose {
                dismiss()
            }
        }
    }
    
    func handleImportFile(result: Result<URL, Error>) {
        do {
            switch result {
            case .success(let url):
                filePath = url
                newPaper.title = url.deletingPathExtension().lastPathComponent
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                if didStartAccessing {
                    let savedURL = try FilePath.paperDirectory(for: newPaper, create: true)
                        .appending(path: url.lastPathComponent)
                    try FileManager.default.copyItem(at: url, to: savedURL)
                    newPaper.localFile = savedURL
                    shouldGoNext = true
                } else {
                    errorMsg = String(localized: "You don't have access to the PDF.")
                }
            case .failure(let error):
                throw error
            }
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}

#Preview {
    AddPaperView(project: ModelData.project1)
        .modelContainer(previewContainer)
}
