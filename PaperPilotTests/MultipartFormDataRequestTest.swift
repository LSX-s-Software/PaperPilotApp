//
//  MultipartFormDataRequestTest.swift
//  PaperPilotTests
//
//  Created by 林思行 on 2023/11/4.
//

import XCTest
@testable import PaperPilot

final class MultipartFormDataRequestTest: XCTestCase {
    let url = URL(string: "https://www.apple.com")!
#if os(macOS)
    let image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: nil)!
#else
    let image = UIImage(systemName: "circle.fill")!
#endif

    func testAddTextField() throws {
        let request = MultipartFormDataRequest(url: url)
        request.addTextField(named: "name", value: "John Doe")

        let expectedBody = """
            --\(request.boundary)\r
            Content-Disposition: form-data; name="name"\r
            Content-Type: text/plain; charset=ISO-8859-1\r
            Content-Transfer-Encoding: 8bit\r
            \r
            John Doe\r\n
            """

        XCTAssertEqual(request.httpBody as Data, expectedBody.data(using: .utf8))
    }

    func testAddDataField() throws {
        let request = MultipartFormDataRequest(url: url)
        let imageData = image.pngData()!
        request.addDataField(named: "image", data: imageData, mimeType: "image/png")

        let expectedBody = """
            --\(request.boundary)\r
            Content-Disposition: form-data; name="image"\r
            Content-Type: image/png\r
            \r\n
            """
        let expectedBodyData = NSMutableData(data: expectedBody.data(using: .utf8)!)
        expectedBodyData.append(imageData)
        expectedBodyData.append("\r\n")

        XCTAssertEqual(request.httpBody, expectedBodyData)
    }

    func testURLRequest() throws {
        let request = MultipartFormDataRequest(url: url)
        request.addTextField(named: "name", value: "John Doe")
        let imageData = image.pngData()!
        request.addDataField(named: "image", data: imageData, mimeType: "image/png")

        let urlRequest = request.urlRequest

        XCTAssertEqual(urlRequest.url, request.url)
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "multipart/form-data; boundary=\(request.boundary)")
        XCTAssertEqual(urlRequest.httpBody, request.httpBody as Data)
    }

    func testEmoji() throws {
        let request = MultipartFormDataRequest(url: url)
        request.addTextField(named: "name", value: "👨‍👩‍👧‍👦")
        
        let expectedBody = """
            --\(request.boundary)\r
            Content-Disposition: form-data; name="name"\r
            Content-Type: text/plain; charset=ISO-8859-1\r
            Content-Transfer-Encoding: 8bit\r
            \r
            👨‍👩‍👧‍👦\r\n
            """

        XCTAssertEqual(request.httpBody as Data, expectedBody.data(using: .utf8))
    }

    func testMultipleField() throws {
        let request = MultipartFormDataRequest(url: url)
        request.addTextField(named: "name1", value: "value1")
        request.addTextField(named: "name2", value: "value2")
        let imageData = image.pngData()!
        request.addDataField(named: "file", data: imageData, mimeType: "text/plain")
        
        let expectedBody = """
            --\(request.boundary)\r
            Content-Disposition: form-data; name="name1"\r
            Content-Type: text/plain; charset=ISO-8859-1\r
            Content-Transfer-Encoding: 8bit\r
            \r
            value1\r
            --\(request.boundary)\r
            Content-Disposition: form-data; name="name2"\r
            Content-Type: text/plain; charset=ISO-8859-1\r
            Content-Transfer-Encoding: 8bit\r
            \r
            value2\r
            --\(request.boundary)\r
            Content-Disposition: form-data; name="file"\r
            Content-Type: text/plain\r
            \r\n
            """
        let expectedBodyData = NSMutableData(data: expectedBody.data(using: .utf8)!)
        expectedBodyData.append(imageData)
        expectedBodyData.append("\r\n")

        XCTAssertEqual(request.httpBody, expectedBodyData)
    }
}
