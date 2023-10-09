//
//  ContentView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI

struct ContentView: View {
    @State private var isShowingAccountView = false
    var body: some View {
        ProjectList()
            .toolbar {
                ToolbarItem {
                    Button("Account", systemImage: "person.crop.circle") {
                        isShowingAccountView = true
                    }

                    .sheet(
                        isPresented: $isShowingAccountView,
                        onDismiss: {},
                        content: {
                            AccountView(
                                isShowingAccountView:
                                    $isShowingAccountView)
                        }
                    )
                }
            }
    }
}

#Preview {
    ContentView()
        .environmentObject(ModelData())
}
