//
//  AddTagView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/2.
//

import SwiftUI

struct AddTagView: View {
    @State var editing = false
    @State var text = ""
    
    let onCommit: (String) -> Void
    
    var body: some View {
        Button("Add", systemImage: "plus") {
            editing.toggle()
        }
        .popover(isPresented: $editing) {
            HStack {
                TextField("New Tag", text: $text)
                    .textFieldStyle(.roundedBorder)
                
                Button("Add") {
                    editing = false
                    if !text.isEmpty {
                        onCommit(text)
                        text = ""
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
    }
}

#Preview {
    AddTagView() { tag in
        print(tag)
    }
    .padding()
}
