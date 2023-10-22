//
//  OSSRequest.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/21.
//

import Foundation

struct OSSRequest {
    private var request: MultipartFormDataRequest

    init?(token: Util_OssToken, fileName: String, fileData: Data, mimeType: String) {
        guard let host = URL(string: token.host),
              let policyData = Data(base64Encoded: token.policy),
              let policyObject = try? JSONSerialization.jsonObject(with: policyData) as? [String: Any],
              let conditions = policyObject["conditions"] as? [Any] else { return nil }
        var key: String?
        for condition in conditions {
            if let condition = condition as? [String], condition.count == 3, condition[1] == "$key" {
                if condition[0] == "eq" {
                    key = condition[2]
                } else if condition[0] == "starts-with" {
                    key = condition[2] + fileName
                }
                break
            }
        }
        self.request = MultipartFormDataRequest(url: host)
        request.addTextField(named: "key", value: key ?? fileName)
        request.addTextField(named: "OSSAccessKeyId", value: token.accessKeyID)
        request.addTextField(named: "policy", value: token.policy)
        request.addTextField(named: "signature", value: token.signature)
        request.addTextField(named: "callback", value: token.callbackBody)
        request.addDataField(named: "file", data: fileData, mimeType: mimeType)
    }

    var urlRequest: URLRequest {
        request.urlRequest
    }
}

extension URLSession {
    func upload(for request: OSSRequest) async throws {
        let (data, response) = try await self.upload(for: request.urlRequest, from: request.urlRequest.httpBody!)
        if let response = response as? HTTPURLResponse,
           !(200...299).contains(response.statusCode) {
            let responseXML = try? XMLDocument(data: data).rootElement()
            let message = responseXML?.children?.compactMap { $0.name == "Code" || $0.name == "Message" ? $0.stringValue : nil }
            throw NetworkingError.requestError(code: response.statusCode,
                                               message: message?.joined(separator: ": ") ?? String(localized: "Unknown error"))
        }
    }
}
