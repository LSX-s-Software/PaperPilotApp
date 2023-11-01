//
//  SharedData.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/11/1.
//

import Foundation
import PDFKit

struct SharedNote: Codable {
    var content = ""
    var timestamp = Date.now.ISO8601Format()
}

struct SharedAnnotation: Codable {
    struct Annotation: Codable {
        /// 区域
        var bounds: CGRect
        /// 类型
        var type: PDFAnnotationSubtype.RawValue
        /// 作者ID
        var authorId: User.ID
    }

    var annotations = [String: Annotation]()
}
