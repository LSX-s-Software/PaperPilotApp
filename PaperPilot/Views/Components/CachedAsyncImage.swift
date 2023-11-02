//
//  CacheAsyncImage.swift
//  PaperPilot
//
//  Created by mike on 2023/10/20.
//

import SwiftUI

private enum LoadState {
    case success(Image)
    case error(any Error)
    case empty
}

enum AsyncImageError: LocalizedError {
    case dataNotImage

    var errorDescription: String? {
        switch self {
        case .dataNotImage:
            String(localized: "Data downloaded cannot be converted to an NSImage.")
        }
    }
}

struct CachedAsyncImage<I: View, P: View, F: View>: View, Equatable {
    @State private var state: LoadState = .empty
    private var url: URL?
    private let content: (Image) -> I
    private let placeholder: () -> P
    private let failure: (any Error) -> F
    private let request: URLRequest?
    private let session: URLSession
    private var isFirstLoad = true

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.url == rhs.url
    }

    public init(
        url: URL?,
        cache: URLCache = .shared,
        @ViewBuilder content: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P,
        @ViewBuilder failure: @escaping (any Error) -> F
    ) {
        self.content = content
        self.placeholder = placeholder
        self.failure = failure

        let conf = URLSessionConfiguration.default
        conf.urlCache = cache
        self.session = URLSession(configuration: conf)

        self.url = url

        guard let url = url else {
            self.request = nil
            self._state = State(initialValue: .empty)
            return
        }
        let request = URLRequest(url: url)
        if let image =
            cache.cachedResponse(for: request).flatMap({ response in
                NSImage(data: response.data)
            }) {
            self.request = nil
            self._state = State(initialValue: .success(Image(nsImage: image)))
        } else {
            self.request = request
            self._state = State(initialValue: .empty)
        }
    }

    public init(
        url: URL?,
        cache: URLCache = .shared,
        @ViewBuilder content: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) where F == Text {
        self.init(url: url, cache: cache, content: content, placeholder: placeholder) { _ in
            Text("Error")
        }
    }

    public init(
        url: URL?,
        cache: URLCache = .shared,
        @ViewBuilder placeholder: @escaping () -> P
    ) where F == Text, I == Image {
        self.init(
            url: url,
            cache: cache,
            content: { $0 },
            placeholder: placeholder,
            failure: { _ in Text("Error") }
        )
    }

    public init(
        url: URL?,
        cache: URLCache = .shared
    ) where F == Text, I == Image, P == ProgressView<EmptyView, EmptyView> {
        self.init(
            url: url,
            cache: cache,
            placeholder: { ProgressView() }
        )
    }

    public init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> I,
        cache: URLCache = .shared
    ) where F == Text, P == ProgressView<EmptyView, EmptyView> {
        self.init(
            url: url,
            cache: cache,
            content: content,
            placeholder: { ProgressView() }
        )
    }

    var body: some View {
        return Group {
            switch self.state {
            case .empty:
                self.placeholder()
            case let .error(e):
                self.failure(e)
            case let .success(image):
                self.content(image)
            }
        }
        .task(id: url, load)
    }

    @Sendable
    private func load() async {
        guard let request = self.request else {
            return
        }
        do {
            let (data, _) = try await session.data(for: request)
            guard let nsImage = NSImage(data: data) else {
                throw AsyncImageError.dataNotImage
            }
            withAnimation {
                self.state = .success(Image(nsImage: nsImage))
            }
        } catch {
            print(error)
            self.state = .error(error)
        }
    }
}

 #Preview {
     CachedAsyncImage(url: URL(string: "https://ui-avatars.com/api/?name=default+lin&size=120&background=random"))
 }
