//
//  PaperHelperApp.swift
//  PaperHelper
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI

enum AppWindow: String, Identifiable {
    case main
    case reader
    
    var id: String {
        self.rawValue
    }
}

@main
struct PaperHelperApp: App {
    @StateObject private var modelData = ModelData()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelData)
        }
        .commands {
            SidebarCommands()
        }
        
        WindowGroup("论文阅读", id: AppWindow.reader.id, for: Paper.self) { $paper in
            PaperReader(paper: paper ?? Paper(id: 0, name: "加载中"))
        }
        .commands {
            CommandGroup(replacing: .newItem, addition: { })
        }
    }
}
