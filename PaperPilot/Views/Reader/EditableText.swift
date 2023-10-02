//
//  EditableText.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/9/28.
//

import SwiftUI

struct EditableText: View {
    let text: String?
    let prompt: String
    let onEditEnd: (String) -> Void
    
    @State private var newValue: String
    @State var editing = false

    init(_ text: String?,
         prompt: String = "请输入内容",
         onEditEnd: @escaping (String) -> Void) {
        self.text = text
        self.prompt = prompt
        self.newValue = text ?? ""
        self.onEditEnd = onEditEnd
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Text(text ?? "未知")
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.secondary)
                .opacity(editing ? 0 : 1)

            TextField(prompt, text: $newValue, onEditingChanged: { _ in }) {
                editing = false
                onEditEnd(newValue)
            }
            .multilineTextAlignment(.trailing)
            .opacity(editing ? 1 : 0)
        }
        .onTapGesture(count: 2) {
            editing = true
        }
        .contextMenu {
            Button("Edit", systemImage: "pencil") {
                editing = true
            }
        }
        .onExitCommand(perform: cancelEdit)
    }
    
    func cancelEdit() {
        editing = false
        if let text = text {
            newValue = text
        } else {
            newValue = ""
        }
    }
}

#Preview {
    EditableText("这是一段可编辑的文字") { value in
        print("new’s value is \(value)")
    }
    .padding()
}
