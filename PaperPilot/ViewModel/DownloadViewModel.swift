//
//  DownloadViewModel.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/10/17.
//

import SwiftUI

class DownloadViewModel: ObservableObject {
    @Published var downloading = false
    @Published var downloadProgress: Progress?
    private var downloadTask: URLSessionDownloadTask?
    private var observation: NSKeyValueObservation?

    func downloadFile(from url: URL,
                      parentProgress: Progress? = nil,
                      success: @escaping (URL) -> Void,
                      fail: @escaping (Error) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.downloading = true
        }
        downloadTask = URLSession.shared.downloadTask(with: url) { [weak self] localURL, _, error in
            self?.observation = nil
            self?.downloadTask = nil
            DispatchQueue.main.async { [weak self] in
                self?.downloading = false
            }
            guard let localURL = localURL, error == nil else {
                print("Download error: \(error?.localizedDescription ?? "Unknown error")")
                fail(error!)
                return
            }
            print("File downloaded to: \(localURL)")
            success(localURL)
        }

        if let parentProgress = parentProgress {
            parentProgress.addChild(downloadTask!.progress, withPendingUnitCount: 1)
        }
        observation = downloadTask!.progress.observe(\.fractionCompleted) { progress, _  in
            DispatchQueue.main.async { [weak self] in
                self?.downloadProgress = progress
            }
        }
        
        downloadTask!.resume()
    }
    
    func downloadFile(from url: URL, parentProgress: Progress? = nil) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            downloadFile(from: url, parentProgress: parentProgress) { url in
                continuation.resume(returning: url)
            } fail: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        observation = nil
    }
}
