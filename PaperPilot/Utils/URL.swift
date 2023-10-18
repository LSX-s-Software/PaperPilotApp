//
//  URL.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/18.
//

import Foundation

#if os(macOS)
let bookmarkResOptions: URL.BookmarkResolutionOptions = [.withSecurityScope]
let bookmarkCreationOptions: URL.BookmarkCreationOptions = [.withSecurityScope]
#else
let bookmarkResOptions: URL.BookmarkResolutionOptions = []
let bookmarkCreationOptions: URL.BookmarkCreationOptions = []
#endif
