//
//  AddPaperByURLView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/10.
//

import SwiftUI

struct AddPaperByURLView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var project: Project
    @Binding var shouldClose: Bool
    
    @State private var url = ""
    @State private var isDoi = true
    @State private var paper: Paper?
    @State private var errorMsg: String?
    
    var body: some View {
        ImageTitleForm("Add Paper By URL/DOI", systemImage: "link") {
            Section {
                Picker("Type", selection: $isDoi) {
                    Text("DOI").tag(true)
                    Text("URL").tag(false)
                }
                .pickerStyle(.segmented)

                TextField("Please enter \(isDoi ? "DOI" : "URL")", text: $url)
            } footer: {
                Text(isDoi
                     ? "DOI's format looks like \"10.xxxx/yyyy\""
                     : "You can also search paper using Sci-Hub supported format.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                AsyncButton("Resolve", disabled: url.isEmpty || isDoi && !url.hasPrefix("10.")) {
                    await handleResolvePaper()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .sheet(item: $paper) { paper in
            NewPaperInfoView(project: project,
                             paper: paper,
                             shouldClose: $shouldClose)
        }
        .alert("Failed to resolve paper", isPresented: Binding { errorMsg != nil } set: { _ in errorMsg = nil}) {} message: {
            Text(errorMsg ?? String(localized: "Unknown error"))
        }
    }
    
    func handleResolvePaper() async {
        do {
            paper = isDoi ? try await Paper(doi: url) : try await Paper(query: url)
        } catch NetworkingError.notFound, NetworkingError.responseFormatError {
            errorMsg = String(localized: "Relevant paper info not found")
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}

#Preview {
    AddPaperByURLView(project: ModelData.project1, shouldClose: .constant(true))
        .modelContainer(previewContainer)
        .frame(width: 400)
}
