//
//  ShareExtensionView.swift
//  PaperPilotShareExtension
//
//  Created by 林思行 on 2023/11/14.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ShareExtensionView: View {
    var modelContainer: ModelContainer
    var modelContext: ModelContext

    var itemProviders: [NSItemProvider]
    @State private var loading = true
    @State private var newPapers = [Paper]()
    @State private var statuses = [Result<Bool, Error>]()
    @State private var errorMsg: String?
    @State private var projects: [Project]
    @State private var selectedProjectId: Project.ID
    @State private var importing = false

    var close: () -> Void

    init(itemProviders: [NSItemProvider], close: @escaping () -> Void) {
        self.itemProviders = itemProviders
        self.close = close
        do {
            self.modelContainer = try ModelContainer(for: Paper.self, Project.self, Bookmark.self, User.self, MicroserviceStatus.self)
            self.modelContext = ModelContext(modelContainer)
            let projects = try modelContext.fetch(FetchDescriptor<Project>())
            self._projects = State(initialValue: projects)
            self._selectedProjectId = State(initialValue: projects.first?.id ?? Project.ID())
        } catch {
            fatalError("Could not initialize ModelContainer: \(error.localizedDescription)")
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView("Loading...")
                } else if newPapers.isEmpty || errorMsg != nil {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .imageScale(.large)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.red)
                            .font(.title)
                        Text("Failed to import this file")
                            .foregroundStyle(.secondary)
                            .font(.title)
                        Text(errorMsg ?? String(localized: "Unsupported file type"))
                            .foregroundStyle(.secondary)
                            .font(.title3)
                        Button("Cancel", role: .cancel, action: close)
                    }
                } else {
                    Form {
                        Section {
                            ForEach(Array(newPapers.enumerated()), id: \.offset) { index, paper in
                                LabeledContent(paper.title) {
                                    switch statuses[index] {
                                    case .success(let imported):
                                        if imported {
                                            Label("Imported", systemImage: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                        } else {
                                            Text(paper.localFile?.lastPathComponent ?? "")
                                        }
                                    case .failure(let error):
                                        Label(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.red)
                                    }
                                }
                            }
                        }
                        Section("Import to") {
                            Picker("Project", selection: $selectedProjectId) {
                                ForEach(projects) { project in
                                    Text(project.name).tag(project.id)
                                }
                            }
                            HStack {
                                Button("Cancel", role: .cancel, action: close)
                                AsyncButton("Import") {
                                    handleImport()
                                }
                                .keyboardShortcut(.defaultAction)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .formStyle(.grouped)
                }
            }
            .padding()
            .navigationTitle("Import Files to Paper Pilot")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel, action: close)
                }
                ToolbarItem(placement: .confirmationAction) {
                    AsyncButton("Import") {
                        handleImport()
                    }
                }
            }
        }
        .task {
            do {
                for itemProvider in itemProviders {
                    if itemProvider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier),
                       let urlData = try await itemProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? Data,
                       let url = URL(dataRepresentation: urlData, relativeTo: nil),
                       url.pathExtension == "pdf" {
                        let paper = Paper(title: url.deletingPathExtension().lastPathComponent)
                        paper.localFile = url
                        newPapers.append(paper)
                        statuses.append(.success(false))
                    }
                }
            } catch {
                errorMsg = error.localizedDescription
            }
            loading = false
        }
    }

    func handleImport() {
        guard let selectedProject = projects.first(where: { $0.id == selectedProjectId }) else { return }
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.appGroupId)?
            .appending(path: "Library/Caches/ImportedFiles") else { return }
        if !FileManager.default.fileExists(atPath: containerURL.path) {
            do {
                try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
            } catch {
                errorMsg = error.localizedDescription
                return
            }
        }
        importing = true
        for (index, paper) in newPapers.enumerated() {
            do {
                guard let url = paper.localFile else { continue }
                paper.project = selectedProject
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                if didStartAccessing {
                    let savedURL = containerURL.appending(path: "\(paper.id.uuidString).pdf")
                    try FileManager.default.copyItem(at: url, to: savedURL)
                    paper.localFile = savedURL
                    if selectedProject.remoteId != nil {
                        paper.status = ModelStatus.waitingForUpload.rawValue
                    }
                    modelContext.insert(paper)
                    statuses[index] = .success(true)
                } else {
                    statuses[index] = .failure(String(localized: "You don't have access to the PDF."))
                    modelContext.delete(paper)
                }
            } catch {
                statuses[index] = .failure(error)
            }
        }
        importing = false
        if statuses.allSatisfy({
            if case let .success(imported) = $0 {
                return imported
            } else {
                return false
            }
        }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                close()
            }
        }
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
