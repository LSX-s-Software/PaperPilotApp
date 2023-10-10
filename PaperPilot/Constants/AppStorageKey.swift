//
//  AppStorageKey.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/10.
//

import Foundation

enum AppStorageKey {
    enum User: String {
        case loggedIn = "user.loggedIn"
    }
    
    enum Reader: String {
        case sidebarContent = "reader.sidebarContent"
    }
}
