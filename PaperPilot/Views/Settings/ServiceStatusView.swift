//
//  ServiceStatusView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/24.
//

import SwiftUI

enum ServiceStatus {
    case unknown
    case available
    case unavailable

    var localizedString: String {
        switch self {
        case .unknown:
            return String(localized: "Testing")
        case .available:
            return String(localized: "Available")
        case .unavailable:
            return String(localized: "Unavailable")
        }
    }
}

struct ServiceStatusRow: View {
    var name: LocalizedStringKey
    var status: ServiceStatus

    var body: some View {
        LabeledContent(name) {
            HStack(spacing: 8) {
                if status == .unknown {
                    ProgressView().controlSize(.small)
                } else {
                    Circle()
                        .foregroundColor(status == .available ? .green : .red)
                        .frame(width: 10, height: 10)
                }
                Text(status.localizedString)
            }
        }
    }
}

struct ServiceStatusView: View {
    @State private var serverOnline = ServiceStatus.unknown

    var body: some View {
        Form {
            Section("Servers") {
                ServiceStatusRow(name: "Main Server:", status: serverOnline)
            }

            Divider()

            Section("Services") {
                ServiceStatusRow(name: "Auth:", status: serverOnline)
                ServiceStatusRow(name: "User:", status: serverOnline)
                ServiceStatusRow(name: "Project:", status: serverOnline)
                ServiceStatusRow(name: "Paper:", status: serverOnline)
                ServiceStatusRow(name: "Translation:", status: serverOnline)
            }
        }
        .padding()
        .task {
            serverOnline = (try? await API.shared.test.test(.init())) != nil ? .available : .unavailable
        }
    }
}

#Preview {
    ServiceStatusView()
}
