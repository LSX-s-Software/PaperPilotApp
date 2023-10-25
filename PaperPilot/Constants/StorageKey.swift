//
//  StorageKey.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/10.
//

import Foundation

enum AppStorageKey {
    enum User: String {
        case loggedIn = "user.loggedIn"
        case user = "user.user"
        case accessToken = "user.accessToken"
        case accessTokenExpireTime = "user.accessToken.expire"
        case refreshToken = "user.refreshToken"
        case refreshTokenExpireTime = "user.refreshToken.expire"
        case id = "user.id"
        case phone = "user.phone"
        case avatar = "user.avatar"
        case username = "user.username"
    }

    enum Reader: String {
        case sidebarContent = "reader.sidebarContent"
        case isShowingInspector = "reader.isShowingInspector"
    }
}

enum SceneStorageKey {
    enum Table: String {
        case customizations = "table.customizations"
    }
}
