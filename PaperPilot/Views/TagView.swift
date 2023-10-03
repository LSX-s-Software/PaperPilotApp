//
//  TagView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI

struct TagView: View {
    var text: String?
    var systemImage: String?
    
    var onEdit: ((String) -> Void)?
    var onDelete: (() -> Void)?
    
    @State var editing = false
    @State var newText = ""
    
    var body: some View {
        HStack(spacing: 4) {
            if let systemImage = systemImage {
                Image(systemName: systemImage)
            }
            if let text = text {
                Text(text)
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
        .foregroundStyle(.white)
        .background(Color.accentColor.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .contextMenu {
            if onEdit != nil {
                Button("Edit", systemImage: "pencil") {
                    newText = text ?? ""
                    editing = true
                }
            }
            if let onDelete = onDelete {
                Button("Delete", systemImage: "trash", action: onDelete)
            }
        }
        .popover(isPresented: $editing) {
            HStack {
                TextField("New Tag", text: $newText)
                    .textFieldStyle(.roundedBorder)
                
                Button("Add") {
                    editing = false
                    if !newText.isEmpty {
                        onEdit?(newText)
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
    }
}

#Preview {
    TagView(text: "Tag") { newValue in
        print("Edit: \(newValue)")
    } onDelete: {
        print("Delete")
    }
    .padding()
}
