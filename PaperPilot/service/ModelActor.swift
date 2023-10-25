//
//  ModelActor.swift
//  PaperPilot
//
//  Created by mike on 2023/10/24.
//

import Foundation
import SwiftData
import SwiftUI

@ModelActor
actor PPModelActor {
    static var shared: PPModelActor!

    static func createSharedInstance(modelContainer: ModelContainer) {
        shared = Self(modelContainer: modelContainer)
    }

    @AppStorage(AppStorageKey.User.id.rawValue)
    var userID: String?
}
