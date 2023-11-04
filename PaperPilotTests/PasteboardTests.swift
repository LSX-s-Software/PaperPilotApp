//
//  PasteboardTest.swift
//  PaperPilotTests
//
//  Created by 林思行 on 2023/11/4.
//

import XCTest
@testable import PaperPilot

final class PasteboardTests: XCTestCase {

    override func setUpWithError() throws {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        #else
        UIPasteboard.general.string = nil
        #endif
    }

    func testSetPasteboard() {
        let string = "Hello, world!"
        setPasteboard(string)
        
        #if os(macOS)
        let contents = NSPasteboard.general.string(forType: .string)
        #else
        let contents = UIPasteboard.general.string
        #endif
        
        XCTAssertEqual(contents, string)
    }

    func testSetEmptyString() {
        let string = ""
        setPasteboard(string)
        
        #if os(macOS)
        let contents = NSPasteboard.general.string(forType: .string)
        #else
        let contents = UIPasteboard.general.string
        #endif
        
        XCTAssertEqual(contents, string)
    }

}
