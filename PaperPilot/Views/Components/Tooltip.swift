//
//  Tooltip.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/24.
//

import SwiftUI

#if os(macOS)
extension View {
    func toolTip(_ toolTip: String?) -> some View {
        self.overlay(TooltipView(toolTip))
    }
}

struct TooltipView: NSViewRepresentable {
    let toolTip: String?

    init(_ toolTip: String?) {
        self.toolTip = toolTip
    }

    func makeNSView(context: NSViewRepresentableContext<TooltipView>) -> NSView {
        let view = NSView()
        view.toolTip = self.toolTip
        return view
    }

    func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<TooltipView>) { }
}
#endif
