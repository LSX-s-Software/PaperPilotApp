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
    
    var body: some View {
        NavigationStack {
            ImageTitleDialog(title: "Add Paper", systemImage: "doc.fill.badge.plus") {
                VStack {
                    NavigationLink {
                        AddPaperByURLView(project: project)
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
                    
                    NavigationLink {
                        AddPaperByFileView(project: project)
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
                }
                .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}

#Preview {
    AddPaperView(project: ModelData.project1)
        .modelContainer(previewContainer)
}
