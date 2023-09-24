//
//  TagView.swift
//  PaperHelper
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI

struct TagView: View {
    var text: String
    
    var body: some View {
        Text(text)
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
            .foregroundStyle(.white)
            .background(Color.accentColor.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

#Preview {
    TagView(text: "Tag")
}
