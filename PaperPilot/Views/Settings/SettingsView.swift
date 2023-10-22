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
    }

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(Tabs.general)

            StorageSpaceSettingsView()
                .tabItem { Label("Storage Space", systemImage: "internaldrive") }
                .tag(Tabs.general)
        }
    }
}

#Preview {
    SettingsView()
        .frame(width: 500)
}
