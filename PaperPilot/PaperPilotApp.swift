//
//  PaperPilotApp.swift
//  PaperPilot
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
struct PaperPilotApp: App {
    @StateObject private var modelData = ModelData()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 500, idealWidth: 1000, maxWidth: .infinity,
                       minHeight: 300, idealHeight: 800, maxHeight: .infinity)
                .environmentObject(modelData)
        }
        .commands {
            SidebarCommands()
        }
        
        WindowGroup("论文阅读", id: AppWindow.reader.id, for: Paper.self) { $paper in
            PaperReader(paper: paper ?? Paper(id: 0, title: "加载中"))
                .frame(minWidth: 500, idealWidth: 1200, maxWidth: .infinity,
                       minHeight: 300, idealHeight: 900, maxHeight: .infinity)
        }
        .commands {
            CommandGroup(replacing: .newItem, addition: { })
        }
    }
}
