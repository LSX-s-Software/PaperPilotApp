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
    var onDismiss: (() -> Void)?

    init(_ title: LocalizedStringKey,
         subtitle: LocalizedStringKey? = nil,
         systemImage: String,
         @ViewBuilder content: @escaping () -> Content,
         onDismiss: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.content = content
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 0) {
            ImageTitle(title, subtitle: subtitle, systemImage: systemImage)

            content()
                .padding(.top)
        }
        .padding()
        .frame(minWidth: 350)
        .fixedSize(horizontal: false, vertical: true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) {
                    onDismiss?()
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
