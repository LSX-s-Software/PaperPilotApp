//
//  ShareCollectionKey.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/27.
//

import Foundation

/// App使用的ShareDB的Collection名称
enum ShareCollectionKey: String {
    /// 笔记
    case notes
    /// 标注
    case annotations
    /// PencilKit画布
    case canvas
}
