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
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack {
            Image(systemName: systemImage)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.blue)
                .font(.system(size: 48))
                .padding(.vertical)
            
            Text(title)
                .font(.title)
                .fontWeight(.medium)
                .padding(.bottom)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom)
            }
            
            content()
                .frame(maxHeight: .infinity)
        }
        .padding()
        .frame(minWidth: 350)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}
