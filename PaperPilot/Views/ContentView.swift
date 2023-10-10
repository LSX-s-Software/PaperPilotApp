//
//  ContentView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/24.
//

import SwiftUI

struct ContentView: View {
    @State private var isShowingLoginSheet = false
    @State private var isShowingAccountView = false
    @State private var haveLoggedIn = false

    var body: some View {
        ProjectList()
            .toolbar {
                ToolbarItem {
                    if !haveLoggedIn {
                        Button {
                            isShowingLoginSheet.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                Text("Login")
                            }
                        }
                        .sheet(isPresented: $isShowingLoginSheet) {
                            LoginSheet()
                        }
                    } else {
                        Button("Account", systemImage: "person.crop.circle") {
                            isShowingAccountView.toggle()
                        }

                        .sheet(isPresented: $isShowingAccountView) {
                            AccountView()
                        }
                    }
                }
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(previewContainer)
}
