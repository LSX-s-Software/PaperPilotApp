//
//  Alert.swift
//  PaperPilot
//
//  Created by mike on 2023/10/24.
//

import Foundation
import SwiftUI

@Observable class Alert {
    var hasFailed: Bool = false
    var errorMsg: String = ""
    var errorDetail: String = ""

    init() {
    }

    func alert(message: String, detail: String) {
        self.hasFailed = true
        self.errorMsg = message
        self.errorDetail = detail
    }
}
