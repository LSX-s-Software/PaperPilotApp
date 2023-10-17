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
    @State private var loading = false
    @State private var errorMsg: String?
    @State private var shouldGoNext = false
    
    var body: some View {
        ImageTitleDialog(title: "Add Paper By URL/DOI", systemImage: "link") {
            Picker("Type", selection: $isDoi) {
                Text("DOI").tag(true)
                Text("URL").tag(false)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            
            TextField("Please enter \(isDoi ? "DOI" : "URL")", text: $url)
                .textFieldStyle(.roundedBorder)
                .disabled(loading)
                
            if !isDoi {
                Text("You can also search paper using Sci-Hub supported format.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .toolbar {
            if !shouldGoNext {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        handleResolvePaper()
                    } label: {
                        if loading {
                            ProgressView()
                                .controlSize(.mini)
                        } else {
                            Text("Retrieve")
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(url.isEmpty || loading)
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
    
    func handleResolvePaper() {
        loading = true
        Task {
            do {
                paper = isDoi ? try await Paper(doi: url) : try await Paper(query: url)
                shouldGoNext = true
            } catch NetworkingError.notFound, NetworkingError.dataFormatError {
                errorMsg = String(localized: "Relevant paper info not found")
            } catch {
                errorMsg = error.localizedDescription
            }
            loading = false
        }
    }
}

#Preview {
    AddPaperByURLView(project: ModelData.project1, shouldClose: .constant(true))
        .modelContainer(previewContainer)
        .frame(width: 400)
}
