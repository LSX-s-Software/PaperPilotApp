//
//  User.swift
//  PaperPilot
//
//  Created by ljx on 2023/10/13.
//

import Foundation

struct User: Codable {
    var accessToken: String
    var phone: String
}

extension User: RawRepresentable {
    public typealias RawValue = String
    public init?(rawValue: RawValue) {
        guard let user = rawValue.data(using: .utf8),
              let user = try? JSONDecoder().decode(User.self, from: user) else {
            return nil
        }
        self = user
    }

    public var rawValue: RawValue {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8) else {
            return ""
        }
        return result
    }
}
