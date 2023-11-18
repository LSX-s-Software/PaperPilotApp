//
//  PaperPilotApp.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI
import SwiftData
import CoreSpotlight
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
    @State private var appState = AppState()
    @StateObject private var navigationContext = NavigationContext()

    init() {
        print("App Home:", NSHomeDirectory())
        do {
            modelContainer = try ModelContainer(for: Paper.self, Project.self, Bookmark.self, User.self, MicroserviceStatus.self)
            ModelService.createSharedInstance(modelContainer: modelContainer)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error.localizedDescription)")
        }
        API.shared.setToken()
    }
    
    var body: some Scene {
        Group {
#if os(macOS)
            Window("Paper Pilot", id: AppWindow.main.id) {
                ContentView()
                    .frame(minWidth: 600, minHeight: 300)
                    .environmentObject(navigationContext)
                    .sheet(isPresented: $appState.isShowingJoinProjectView) {
                        if let url = appState.incomingURL {
                            JoinProjectView(invitationURL: url)
                        } else {
                            JoinProjectView()
                        }
                    }
                    .onOpenURL(perform: appState.handleIncomingURL(url:))
                    .onContinueUserActivity(CSSearchableItemActionType, perform: appState.handleSpotlight)
            }
            .defaultSize(width: 1200, height: 700)
#else
            WindowGroup("Paper Pilot", id: AppWindow.main.id) {
                ContentView()
                    .environmentObject(navigationContext)
                    .sheet(isPresented: $appState.isShowingJoinProjectView) {
                        if let url = appState.incomingURL {
                            JoinProjectView(invitationURL: url)
                        } else {
                            JoinProjectView()
                        }
                    }
                    .onOpenURL(perform: appState.handleIncomingURL(url:))
                    .onContinueUserActivity(CSSearchableItemActionType, perform: appState.handleSpotlight)
            }
#endif
        }
        .modelContainer(modelContainer)
        .commands {
            SidebarCommands()
            ProjectCommands()
        }
        .environment(appState)

        WindowGroup("Paper Reader", id: AppWindow.reader.id, for: PersistentIdentifier.self) { $paperId in
            if let paperId = paperId,
               let paper: Paper = modelContainer.mainContext.registeredModel(for: paperId) {
                PaperReader(paper: paper)
                    .frame(minWidth: 600, minHeight: 400)
            } else {
                Text("This paper does not exist.")
                    .font(.title)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
#if os(macOS)
        .register(AppWindow.reader.id)
        .disableRestoreOnLaunch()
        .defaultSize(width: 1200, height: 800)
#elseif os(visionOS)
        .defaultSize(width: 1920, height: 1200)
#endif
        .modelContainer(modelContainer)
        .commandsRemoved()
        .commands {
            InspectorCommands()
            ToolbarCommands()
            PaperCommands()
        }
        .environment(appState)

#if os(macOS)
        Settings {
            SettingsView()
                .frame(minWidth: 500)
        }
        .modelContainer(modelContainer)
        .defaultPosition(.top)
#endif
    }
}
