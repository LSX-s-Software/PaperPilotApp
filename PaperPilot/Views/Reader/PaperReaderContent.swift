//
//  PaperReader.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/25.
//

import SwiftUI
import PDFKit

struct HSplitViewLayout<Left: View, Right: View>: View {
    @ViewBuilder var left: () -> Left
    @ViewBuilder var right: () -> Right
    
    var body: some View {
#if os(macOS)
        HSplitView {
            left()
            
            right()
        }
#else
        HStack {
            left()
            
            right()
        }
#endif
    }
}

#Preview {
    HSplitViewLayout {
        Text("Left")
    } right: {
        Text("Right")
    }
}
