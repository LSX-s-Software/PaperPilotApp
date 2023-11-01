//
//  HighlighterColor.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/16.
//

import SwiftUI

enum HighlighterColor: String, CaseIterable, Identifiable {
    case yellow = "Yellow"
    case green = "Green"
    case blue = "Blue"
    case pink = "Pink"
    case purple = "Purple"
    case black = "Black"
    
    var id: Self { self }
    
    var color: Color {
        switch self {
        case .yellow:
            Color(red: 249 / 255.0, green: 205 / 255.0, blue: 110 / 255.0)
        case .green:
            Color(red: 142 / 255.0, green: 197 / 255.0, blue: 115 / 255.0)
        case .blue:
            Color(red: 121 / 255.0, green: 175 / 255.0, blue: 235 / 255.0)
        case .pink:
            Color(red: 233 / 255.0, green: 103 / 255.0, blue: 138 / 255.0)
        case .purple:
            Color(red: 191 / 255.0, green: 136 / 255.0, blue: 214 / 255.0)
        case .black:
            Color.black
        }
    }

#if os(macOS)
    var platformColor: NSColor {
        NSColor(color)
    }
#else
    var platformColor: UIColor {
        UIColor(color)
    }
#endif
}
