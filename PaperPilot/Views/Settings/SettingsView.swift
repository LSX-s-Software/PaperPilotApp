//
//  SettingsView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/22.
//

import SwiftUI

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general
        case file
        case serviceStatus
    }

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(Tabs.general)

            StorageSpaceSettingsView()
                .tabItem { Label("Storage Space", systemImage: "internaldrive") }
                .tag(Tabs.file)

            ServiceStatusView()
                .tabItem { Label("Service Status", systemImage: "network") }
                .tag(Tabs.serviceStatus)
        }
    }
}

#Preview {
    SettingsView()
        .frame(width: 500)
}
