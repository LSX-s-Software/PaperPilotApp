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
    @StateObject var navigationContext = NavigationContext()

    init() {
        do {
            modelContainer = try ModelContainer(for: Paper.self, Project.self, Bookmark.self, User.self, MicroserviceStatus.self)
            PPModelActor.createSharedInstance(modelContainer: modelContainer)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error.localizedDescription)")
        }
        API.shared.setToken()
    }
    
    var body: some Scene {
#if os(macOS)
        Window("Paper Pilot", id: AppWindow.main.id) {
            ContentView()
                .frame(minWidth: 600, minHeight: 300)
                .environmentObject(navigationContext)
                .sheet(isPresented: $appState.isShowingJoinProjectView) {
                    if let url = appState.incomingURL {
                        JoinProjectView(invitationURL: url)
                    } else {
                        ProgressView()
                            .padding()
                    }
                }
                .onOpenURL(perform: appState.handleIncomingURL(url:))
        }
        .defaultSize(width: 1200, height: 700)
        .modelContainer(modelContainer)
        .commands {
            SidebarCommands()
        }
#else
        WindowGroup("Paper Pilot", id: AppWindow.main.id) {
            ContentView()
                .frame(minWidth: 600, minHeight: 300)
                .sheet(isPresented: $appState.isShowingJoinProjectView) {
                    if let url = appState.incomingURL {
                        JoinProjectView(invitationURL: url)
                    } else {
                        ProgressView()
                            .padding()
                    }
                }
                .onOpenURL(perform: appState.handleIncomingURL(url:))
        }
        .modelContainer(modelContainer)
#endif
        
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
#endif
        .modelContainer(modelContainer)
        .environmentObject(appState)
        .commandsRemoved()
        .commands {
            InspectorCommands()
            
            CommandGroup(after: .textEditing) {
                Button(appState.findingInPDF ? "Stop Finding" : "Find in PDF") {
                    appState.findInPDFHandler?(!appState.findingInPDF)
                }
                .keyboardShortcut("f")
            }
        }

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
