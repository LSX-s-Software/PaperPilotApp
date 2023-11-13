//
//  ChatMessage.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/11/13.
//

import Foundation

struct ChatMessage: Identifiable {
    var id: UUID = UUID()
    var isGPT: Bool
    var isNewContext: Bool = false
    var content: String
    var reference: String?
    var errorMsg: String?
    var totalChat: Int32?
    var remainingChat: Int32?

    static func greeting(for username: String) -> Self {
        ChatMessage(isGPT: true, content: String(localized: """
Hello @\(username)! Feel free to ask questions about the paper you're reading.
If you want to refer to the contents in the PDF, please select them to let me know.
"""))
    }
}
