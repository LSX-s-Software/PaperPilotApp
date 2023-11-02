//
//  AvatarView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/16.
//

import SwiftUI

struct AvatarView: View {
    var url: URL?
    var size: CGFloat = 40

    @AppStorage(AppStorageKey.User.avatar.rawValue)
    private var avatar: String = ""
    private var controlSize: ControlSize {
        switch size {
        case 0...16:
                .mini
        case 17...40:
                .small
        case 64...:
                .large
        default:
                .regular
        }
    }
    
    var body: some View {
        CachedAsyncImage(url: url ?? URL(string: avatar)) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            ProgressView()
                .controlSize(controlSize)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

#Preview {
    AvatarView()
        .padding()
}
