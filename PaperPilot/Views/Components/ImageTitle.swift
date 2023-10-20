//
//  ImageTitle.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/20.
//

import SwiftUI

struct ImageTitle: View {
    var title: LocalizedStringKey
    var subtitle: LocalizedStringKey?
    var systemImage: String

    init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, systemImage: String) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }

    var body: some View {
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
    }
}

#Preview {
    ImageTitle("Create New Project",
               subtitle: "Create New Project",
               systemImage: "folder.fill.badge.plus")
}
