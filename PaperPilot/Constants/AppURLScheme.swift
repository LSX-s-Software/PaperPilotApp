//
//  AppURLScheme.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/20.
//

import Foundation

// swiftlint:disable nesting

final class AppURLScheme {
    static let scheme = "paperpilot"

    enum Hosts: String {
        case project
    }

    enum QueryKeys {
        enum Project: String {
            case invitation
        }
    }

    var host: Hosts
    var queryItems: [URLQueryItem]
    var url: URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = host.rawValue
        components.queryItems = queryItems
        return components.url!
    }

    init(host: Hosts, queryItems: [URLQueryItem] = []) {
        self.host = host
        self.queryItems = queryItems
    }
}

// swiftlint:enable nesting
