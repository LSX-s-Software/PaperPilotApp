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
    @State private var shouldGoNext = false
    
    var body: some View {
        ImageTitleDialog("Add Paper By URL/DOI", systemImage: "link") {
            Picker("Type", selection: $isDoi) {
                Text("DOI").tag(true)
                Text("URL").tag(false)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            
            VStack(alignment: .leading) {
                TextField("Please enter \(isDoi ? "DOI" : "URL")", text: $url)
                    .textFieldStyle(.roundedBorder)

                Text(isDoi
                     ? "DOI's format looks like \"10.xxxx/yyyy\""
                     : "You can also search paper using Sci-Hub supported format.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(height: 20, alignment: .top)
            }
        }
        .toolbar {
            if !shouldGoNext {
                ToolbarItem(placement: .confirmationAction) {
                    AsyncButton("Resolve", disabled: url.isEmpty || isDoi && !url.hasPrefix("10.")) {
                        await handleResolvePaper()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .navigationDestination(isPresented: $shouldGoNext) {
            NewPaperInfoView(project: project,
                             paper: paper ?? Paper(title: ""),
                             shouldClose: $shouldClose)
        }
        .alert(errorMsg ?? "", isPresented: Binding { errorMsg != nil } set: { _ in errorMsg = nil}) {}
    }
    
    func handleResolvePaper() async {
        do {
            paper = isDoi ? try await Paper(doi: url) : try await Paper(query: url)
            shouldGoNext = true
        } catch NetworkingError.notFound, NetworkingError.dataFormatError {
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
