//
//  PaperPilotApp.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI
import SwiftData
import WindowManagement

enum AppWindow: String, Identifiable {
    case main
    case reader
    
    var id: String {
        self.rawValue
    }
}

@main
struct PaperPilotApp: App {
    let modelContainer: ModelContainer
    @StateObject var appState = AppState()
    
    @AppStorage(AppStorageKey.User.accessToken.rawValue)
    private var accessToken: String?

    init() {
        do {
            modelContainer = try ModelContainer(for: Paper.self, Project.self, Bookmark.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error.localizedDescription)")
        }
        if let accessToken = self.accessToken {
            API.shared.setToken(accessToken)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, idealWidth: 1000, maxWidth: .infinity,
                       minHeight: 400, idealHeight: 800, maxHeight: .infinity)
        }
        .modelContainer(modelContainer)
        .commands {
            SidebarCommands()
        }
        
        WindowGroup("Paper Reader", id: AppWindow.reader.id, for: Paper.self) { $paper in
            PaperReader(paper: paper ?? Paper(title: "Loading"))
                .navigationTitle(paper?.title ?? "Paper Reader")
                .frame(minWidth: 600, idealWidth: 1200, maxWidth: .infinity,
                       minHeight: 400, idealHeight: 900, maxHeight: .infinity)
        }
        .register(AppWindow.reader.id)
        .disableRestoreOnLaunch()
        .modelContainer(modelContainer)
        .environmentObject(appState)
        .commands {
            CommandGroup(replacing: .newItem, addition: { })
            
            CommandGroup(after: .textEditing) {
                Button(appState.findingInPDF ? "Stop Finding" : "Find in PDF") {
                    appState.findInPDFHandler?(!appState.findingInPDF)
                }
                .keyboardShortcut("f")
            }
        }
    }
}

class AppState: ObservableObject {
    @Published var findingInPDF = false
    var findInPDFHandler: ((Bool) -> Void)?
}
