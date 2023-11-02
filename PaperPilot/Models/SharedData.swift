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
        /// 页码
        var page: Int
        /// 区域
        var bounds: CGRect
        /// 类型
        var type: PDFAnnotationSubtype.RawValue
        /// 颜色
        var color: PlatformColor
        /// 作者ID
        var authorId: User.ID
    }

    var annotations = [String: Annotation]()
    var pdfAnnotations = [String: PDFAnnotation]()

    private enum CodingKeys: String, CodingKey {
        case annotations
    }
}
