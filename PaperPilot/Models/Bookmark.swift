//
//  Bookmark.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/15.
//

import Foundation
import SwiftData

/// 书签
@Model
class Bookmark: Hashable, Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    /// 页码
    var page: Int
    /// 标签
    var label: String?
    
    init(page: Int, label: String?) {
        self.page = page
        self.label = label
    }
}
