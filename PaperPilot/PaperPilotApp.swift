//
//  PaperPilotApp.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI
import SwiftData
#if os(macOS)
import WindowManagement
#endif

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
        WindowGroup("Paper Pilot", id: AppWindow.main.id) {
            ContentView()
                .frame(minWidth: 600, idealWidth: 1000, maxWidth: .infinity,
                       minHeight: 400, idealHeight: 800, maxHeight: .infinity)
                .sheet(isPresented: $appState.isShowingJoinProjectView) {
                    if let url = appState.incomingURL {
                        JoinProjectView(invitationURL: url)
                    } else {
                        ProgressView()
                            .padding()
                    }
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    guard let url = userActivity.webpageURL else { return }
                    appState.incomingURL = url
                    if url.scheme == "paperpilot" && url.host == "project" {
                        appState.isShowingJoinProjectView = true
                    }
                }
                .onOpenURL { url in
                    appState.incomingURL = url
                    if url.scheme == "paperpilot" && url.host == "project" {
                        appState.isShowingJoinProjectView = true
                    }
                }
        }
        .handlesExternalEvents(matching: ["*"])
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
#if os(macOS)
        .register(AppWindow.reader.id)
        .disableRestoreOnLaunch()
#endif
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
