//
//  ImageTitleForm.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/20.
//

import SwiftUI

struct ImageTitleForm<Content: View>: View {
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
        Group {
#if os(macOS)
            VStack(spacing: 0) {
                ImageTitle(title, subtitle: subtitle, systemImage: systemImage)

                Form {
                    content()
                }
                .formStyle(.grouped)
            }
            .frame(idealWidth: 350)
#else
            Form {
                VStack(spacing: 0) {
                    ImageTitle(title, subtitle: subtitle, systemImage: systemImage)
                }
                .frame(maxWidth: .infinity)

                content()
            }
            .frame(minWidth: 350)
#endif
        }
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
    ImageTitleForm(
        "Create New Project",
        subtitle: "Create New Project",
        systemImage: "folder.fill.badge.plus"
    ) {
        TextField("Project Name", text: .constant(""))
    }
    .fixedSize()
    .previewDisplayName("Title and Subtitle")
}

#Preview {
    ImageTitleForm(
        "Create New Project",
        systemImage: "folder.fill.badge.plus"
    ) {
        TextField("Project Name", text: .constant(""))
    }
    .fixedSize()
    .previewDisplayName("Title only")
}
