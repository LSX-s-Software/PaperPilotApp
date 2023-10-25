//
//  MicroserviceStatus.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/25.
//

import SwiftData

@Model
class MicroserviceStatus: Identifiable {
    @Attribute(.unique) var id: String
    /// 服务名称
    var name: String
    /// 服务描述
    var desc: String
    /// 可用服务数
    @Transient
    var healthyCount: Int32 = 0
    /// 总服务数
    @Transient
    var totalCount: Int32 = 0

    init(id: String, name: String, desc: String, healthyCount: Int32, totalCount: Int32) {
        self.id = id
        self.name = name
        self.desc = desc
        self.healthyCount = healthyCount
        self.totalCount = totalCount
    }
}
