//
//  ImageTitleDialog.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/10.
//

import SwiftUI

struct ImageTitleDialog<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    
    var title: LocalizedStringKey
    var subtitle: LocalizedStringKey?
    var systemImage: String
    var content: () -> Content
    
    init(_ title: LocalizedStringKey,
         subtitle: LocalizedStringKey? = nil,
         systemImage: String,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: systemImage)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .font(.system(size: 48))
                .padding(.vertical)
            
            Text(title)
                .font(.title)
                .fontWeight(.medium)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
            
            content()
                .padding(.top)
        }
        .padding()
        .frame(minWidth: 350)
        .fixedSize(horizontal: false, vertical: true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ImageTitleDialog(
        "Create New Project",
        subtitle: "Create New Project",
        systemImage: "folder.fill.badge.plus"
    ) {
        TextField("Project Name", text: .constant(""))
            .textFieldStyle(.roundedBorder)
    }
    .fixedSize()
    .previewDisplayName("Title and Subtitle")
}

#Preview {
    ImageTitleDialog(
        "Create New Project",
        systemImage: "folder.fill.badge.plus"
    ) {
        TextField("Project Name", text: .constant(""))
            .textFieldStyle(.roundedBorder)
    }
    .fixedSize()
    .previewDisplayName("Title only")
}
