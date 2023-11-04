//
//  OSSRequestTest.swift
//  PaperPilotTests
//
//  Created by 林思行 on 2023/11/4.
//

import XCTest
@testable import PaperPilot

final class OSSRequestTests: XCTestCase {

    func testOSSRequest() throws {
        let policy = """
            {
                "expiration": "2014-12-01T12:00:00.000Z",
                "conditions": [
                    {"bucket": "johnsmith" },
                    ["content-length-range", 1, 10],
                    ["eq", "$success_action_status", "201"],
                    ["starts-with", "$key", "user/eric/"],
                    ["in", "$content-type", ["image/jpg", "image/png"]],
                    ["not-in", "$cache-control", ["no-cache"]]
                ]
            }
            """
        var token = Util_OssToken()
        token.host = "https://example.com"
        token.accessKeyID = "accessKeyID"
        token.policy = policy.data(using: .utf8)!.base64EncodedString()
        token.signature = "signature"
        token.callbackBody = "callbackBody"
        let fileName = "testFile.txt"
        let fileData = "Hello, world!".data(using: .utf8)!
        let mimeType = "text/plain"

        let ossRequest = OSSRequest(token: token, fileName: fileName, fileData: fileData, mimeType: mimeType)

        XCTAssertNotNil(ossRequest)
        XCTAssertEqual(ossRequest?.urlRequest.url?.absoluteString, "https://example.com")
        XCTAssertEqual(ossRequest?.urlRequest.httpMethod, "POST")

        let bodyString = try XCTUnwrap(String(data: try XCTUnwrap(ossRequest?.urlRequest.httpBody), encoding: .utf8))
        XCTAssert(bodyString.contains("name=\"key\"\r\nContent-Type: text/plain; charset=ISO-8859-1\r\nContent-Transfer-Encoding: 8bit\r\n\r\nuser/eric/testFile.txt"))
        XCTAssert(bodyString.contains("name=\"OSSAccessKeyId\"\r\nContent-Type: text/plain; charset=ISO-8859-1\r\nContent-Transfer-Encoding: 8bit\r\n\r\naccessKeyID"))
        XCTAssert(bodyString.contains("name=\"policy\"\r\nContent-Type: text/plain; charset=ISO-8859-1\r\nContent-Transfer-Encoding: 8bit\r\n\r\n\(token.policy)"))
        XCTAssert(bodyString.contains("name=\"signature\"\r\nContent-Type: text/plain; charset=ISO-8859-1\r\nContent-Transfer-Encoding: 8bit\r\n\r\nsignature"))
        XCTAssert(bodyString.contains("name=\"callback\"\r\nContent-Type: text/plain; charset=ISO-8859-1\r\nContent-Transfer-Encoding: 8bit\r\n\r\ncallbackBody"))
        XCTAssert(bodyString.contains("name=\"file\"\r\nContent-Type: text/plain\r\n\r\nHello, world!"))
    }

    func testEqPolicy() throws {
        let policy = """
            {
                "expiration": "2014-12-01T12:00:00.000Z",
                "conditions": [
                    {"bucket": "johnsmith"},
                    ["content-length-range", 1, 10],
                    ["eq", "$success_action_status", "201"],
                    ["eq", "$key", "testFile2.txt"],
                    ["in", "$content-type", ["image/jpg", "image/png"]],
                    ["not-in", "$cache-control", ["no-cache"]]
                ]
            }
            """
        var token = Util_OssToken()
        token.host = "https://example.com"
        token.accessKeyID = "accessKeyID"
        token.policy = policy.data(using: .utf8)!.base64EncodedString()
        token.signature = "signature"
        token.callbackBody = "callbackBody"
        let fileName = "testFile.txt"
        let fileData = "Hello, world!".data(using: .utf8)!
        let mimeType = "text/plain"

        let ossRequest = OSSRequest(token: token, fileName: fileName, fileData: fileData, mimeType: mimeType)

        XCTAssertNotNil(ossRequest)
        XCTAssertEqual(ossRequest?.urlRequest.url?.absoluteString, "https://example.com")
        XCTAssertEqual(ossRequest?.urlRequest.httpMethod, "POST")

        let bodyString = try XCTUnwrap(String(data: try XCTUnwrap(ossRequest?.urlRequest.httpBody), encoding: .utf8))
        XCTAssert(bodyString.contains("name=\"key\"\r\nContent-Type: text/plain; charset=ISO-8859-1\r\nContent-Transfer-Encoding: 8bit\r\n\r\ntestFile2.txt"))
        XCTAssert(bodyString.contains("name=\"OSSAccessKeyId\"\r\nContent-Type: text/plain; charset=ISO-8859-1\r\nContent-Transfer-Encoding: 8bit\r\n\r\naccessKeyID"))
        XCTAssert(bodyString.contains("name=\"policy\"\r\nContent-Type: text/plain; charset=ISO-8859-1\r\nContent-Transfer-Encoding: 8bit\r\n\r\n\(token.policy)"))
        XCTAssert(bodyString.contains("name=\"signature\"\r\nContent-Type: text/plain; charset=ISO-8859-1\r\nContent-Transfer-Encoding: 8bit\r\n\r\nsignature"))
        XCTAssert(bodyString.contains("name=\"callback\"\r\nContent-Type: text/plain; charset=ISO-8859-1\r\nContent-Transfer-Encoding: 8bit\r\n\r\ncallbackBody"))
        XCTAssert(bodyString.contains("name=\"file\"\r\nContent-Type: text/plain\r\n\r\nHello, world!"))
    }

    func testOSSRequestWithInvalidToken() throws {
        let invalidToken = Util_OssToken()

        let ossRequest = OSSRequest(token: invalidToken,
                                    fileName: "testFile.txt",
                                    fileData: "Hello, world!".data(using: .utf8)!,
                                    mimeType: "text/plain")

        XCTAssertNil(ossRequest)
    }

    func testOSSRequestWithInvalidPolicy() throws {
        var token = Util_OssToken()
        token.host = "https://example.com"
        token.accessKeyID = "accessKeyID"
        token.policy = "invalidPolicy"
        token.signature = "signature"
        token.callbackBody = "callbackBody"
        let fileName = "testFile.txt"
        let fileData = "Hello, world!".data(using: .utf8)!
        let mimeType = "text/plain"

        XCTAssertNil(OSSRequest(token: token, fileName: fileName, fileData: fileData, mimeType: mimeType))

        token.policy = "invalidPolicy".data(using: .utf8)!.base64EncodedString()
        XCTAssertNil(OSSRequest(token: token, fileName: fileName, fileData: fileData, mimeType: mimeType))

        token.policy = "{".data(using: .utf8)!.base64EncodedString()
        XCTAssertNil(OSSRequest(token: token, fileName: fileName, fileData: fileData, mimeType: mimeType))

        token.policy = "{\"conditions\": []}".data(using: .utf8)!.base64EncodedString()
        let ossRequest1 = OSSRequest(token: token, fileName: fileName, fileData: fileData, mimeType: mimeType)
        XCTAssertNotNil(ossRequest1)
        let bodyString1 = try XCTUnwrap(String(data: try XCTUnwrap(ossRequest1?.urlRequest.httpBody), encoding: .utf8))
        XCTAssert(bodyString1.contains("name=\"key\"\r\nContent-Type: text/plain; charset=ISO-8859-1\r\nContent-Transfer-Encoding: 8bit\r\n\r\ntestFile.txt"))

        token.policy = "{\"conditions\": [\"eq\", \"$key\"]}".data(using: .utf8)!.base64EncodedString()
        let ossRequest2 = OSSRequest(token: token, fileName: fileName, fileData: fileData, mimeType: mimeType)
        XCTAssertNotNil(ossRequest2)
        let bodyString2 = try XCTUnwrap(String(data: try XCTUnwrap(ossRequest2?.urlRequest.httpBody), encoding: .utf8))
        XCTAssert(bodyString2.contains("name=\"key\"\r\nContent-Type: text/plain; charset=ISO-8859-1\r\nContent-Transfer-Encoding: 8bit\r\n\r\ntestFile.txt"))
    }

    func testOSSRequestPerformance() throws {
        let policy = """
            {
                "expiration": "2014-12-01T12:00:00.000Z",
                "conditions": [
                    {"bucket": "johnsmith"},
                    ["content-length-range", 1, 10],
                    ["eq", "$success_action_status", "201"],
                    ["eq", "$key", "testFile2.txt"],
                    ["in", "$content-type", ["image/jpg", "image/png"]],
                    ["not-in", "$cache-control", ["no-cache"]]
                ]
            }
            """
        var token = Util_OssToken()
        token.host = "https://example.com"
        token.accessKeyID = "accessKeyID"
        token.policy = policy.data(using: .utf8)!.base64EncodedString()
        token.signature = "signature"
        token.callbackBody = "callbackBody"
        let fileData = "Hello, world!".data(using: .utf8)!

        measure {
            let ossRequest = OSSRequest(token: token, fileName: "testFile.txt", fileData: fileData, mimeType: "text/plain")?.urlRequest
        }
    }

}
