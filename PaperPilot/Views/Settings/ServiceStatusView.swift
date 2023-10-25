//
//  ServiceStatusView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/24.
//

import SwiftUI
import SwiftData

struct ServiceStatusRow: View {
    let status: MicroserviceStatus
    let loading: Bool

    var body: some View {
        LabeledContent {
            HStack(spacing: 8) {
                if loading {
                    ProgressView().controlSize(.small)
                    Text("Testing...")
                        .foregroundStyle(.secondary)
                } else {
                    if status.healthyCount == status.totalCount {
                        Circle()
                            .foregroundColor(.green)
                            .frame(width: 10, height: 10)
                        Text("Available")
                    } else if status.healthyCount == 0 {
                        Circle()
                            .foregroundColor(.red)
                            .frame(width: 10, height: 10)
                        Text("Unavailable")
                    } else {
                        Circle()
                            .foregroundColor(.yellow)
                            .frame(width: 10, height: 10)
                        Text("Downgraded")
                            .toolTip("Available: \(status.healthyCount)/\(status.totalCount)")
                    }
                }
            }
        } label: {
            Text("\(status.name):")
                .toolTip(status.desc)
        }
    }
}

struct ServiceStatusView: View {
    @Environment(\.modelContext) var modelContext

    @Query(sort: \MicroserviceStatus.id) private var statuses: [MicroserviceStatus]
    @State private var loading = true
    @State private var onlineServers: Int32 = 0
    @State private var latestUpdate = "Never"

    var body: some View {
        Form {
            LabeledContent("Online Servers:") {
                if loading {
                    ProgressView().controlSize(.small)
                } else {
                    Text("\(onlineServers)")
                }
            }

            Divider()

            ForEach(statuses) { status in
                ServiceStatusRow(status: status, loading: loading)
            }

            Divider()

            LabeledContent("Latest update:", value: latestUpdate)
        }
        .padding()
        .task {
            loading = true
            if let status = try? await API.shared.monitor.getStatus(.init()) {
                onlineServers = status.hostCount
                status.projects.forEach { projectStatus in
                    let status = MicroserviceStatus(id: projectStatus.id,
                                                    name: projectStatus.name,
                                                    desc: projectStatus.description_p,
                                                    healthyCount: projectStatus.healthyCount,
                                                    totalCount: projectStatus.totalCount)
                    modelContext.insert(status)
                }
                latestUpdate = status.time.date.formatted()
            }
            loading = false
        }
    }
}

#Preview {
    ServiceStatusView()
        .modelContainer(for: MicroserviceStatus.self, inMemory: true)
}
