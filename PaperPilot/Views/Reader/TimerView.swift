//
//  TimerView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/16.
//

import SwiftUI

struct TimerView: View {
    @State private var timerStartTime: Date?
    
    var body: some View {
        Button {
            timerStartTime = timerStartTime == nil ? Date.now : nil
        } label: {
            Label("Timer", systemImage: "timer")
            if let start = timerStartTime {
                Text(start, style: .timer)
                    .font(.body.monospacedDigit())
            }
        }
    }
}

#Preview {
    Text("Timer")
        .frame(width: 400)
        .toolbar {
            ToolbarItem {
                TimerView()
            }
        }
}
