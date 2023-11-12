//
//  GPTView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/11/11.
//

import SwiftUI
import Combine
import GRPC

struct ChatMessage: Identifiable {
    var id: UUID = UUID()
    var isGPT: Bool
    var content: String
    var reference: String?
    var errorMsg: String?
}

struct GPTView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var pdfVM: PDFViewModel

    @AppStorage(AppStorageKey.User.username.rawValue)
    private var username = ""

    @State private var question = ""
    @State private var generating = false
    @State private var selectionEmpty = true
    @State private var chats = [ChatMessage]()
    let scrollPublisher = PassthroughSubject<Void, Never>()

    var body: some View {
        ScrollViewReader { scrollView in
            List(chats) { chat in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if chat.isGPT {
                            Image("OpenAI")
                                .resizable()
                                .scaledToFit()
                                .padding(6)
                                .frame(width: 28)
                                .foregroundStyle(.primary)
                                .background(.regularMaterial)
                                .clipShape(Circle())
                        } else {
                            AvatarView(size: 28)
                        }
                        Text(chat.isGPT ? "ChatGPT" : username)
                            .font(.title2)
                    }
                    if let reference = chat.reference {
                        Text(reference)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                            .overlay(Rectangle().frame(width: 2.5).foregroundStyle(.tertiary), alignment: .leading)
                    }
                    if !chat.content.isEmpty {
                        Text(chat.content)
                    } else if chat.errorMsg == nil {
                        HStack(spacing: 6) {
                            ProgressView()
#if os(macOS)
                                .controlSize(.small)
#endif
                            Text("Thinking...")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let errorMsg = chat.errorMsg {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(errorMsg)
                        }
                        .foregroundStyle(.red)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.red.opacity(colorScheme == .dark ? 0.3 : 0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.vertical, 8)
                .id(chat.id)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(GPTAction.allCases) { action in
                                Button(String(localized: action.localizedStringResource)) {
                                    sendRequest(action: action)
                                }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.capsule)
                                .disabled(generating || selectionEmpty)
                                .toolTip(selectionEmpty ? String(localized: "Select some text in the PDF") : action.description)
                            }
                        }
                    }
                    .scrollClipDisabled()
                    HStack {
                        TextField("Ask ChatGPT", text: $question)
                            .textFieldStyle(.plain)
                        Button("Ask", systemImage: "paperplane") {
                            sendRequest()
                        }
                        .tint(Color.accentColor)
                        .buttonStyle(.borderless)
                        .labelStyle(.iconOnly)
                        .keyboardShortcut(.defaultAction)
                        .disabled(generating || question.isEmpty)
                    }
                    .padding(10)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(12)
                .background(.bar)
            }
            .onReceive(scrollPublisher.throttle(for: .seconds(0.2), scheduler: RunLoop.main, latest: true)) {
                if let id = chats.last?.id {
                    withAnimation {
                        scrollView.scrollTo(id, anchor: .bottom)
                    }
                }
            }
        }
        .onAppear {
            chats.append(ChatMessage(isGPT: true,
                                     content: String(localized: "Hello @\(username)! Feel free to ask questions about the paper you're reading.")))
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .PDFViewSelectionChanged)
                .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
        ) { _ in
            selectionEmpty = pdfVM.pdfView.currentSelection?.string == nil
        }
    }
}

extension GPTView {
    func displayErrorMessage(_ message: String) {
        if chats.last == nil || !chats.last!.isGPT {
            withAnimation {
                chats.append(ChatMessage(isGPT: true, content: "", errorMsg: message))
            }
        } else {
            chats[chats.count - 1].errorMsg = message
        }
        scrollPublisher.send()
    }

    func sendRequest(action: GPTAction? = nil) {
        guard !generating else { return }
        let request = Ai_GptRequest.with {
            if let currentSelection = pdfVM.pdfView.currentSelection?.string {
                $0.text = currentSelection
            }
            $0.action = action?.rawValue ?? question
        }
        let myMessage = ChatMessage(isGPT: false,
                                    content: action?.description ?? question,
                                    reference: pdfVM.pdfView.currentSelection?.string)
        withAnimation {
            chats.append(myMessage)
            question = ""
            generating = true
        }
        Task {
            scrollPublisher.send()
            do {
            streamLoop: for try await response in API.shared.gpt.ask(request) {
                if response.hasFinishReason {
                    switch response.finishReason {
                    case .null:
                        continue
                    case .stop:
                        break streamLoop
                    default:
                        throw GPTError(reason: response.finishReason)!
                    }
                }
                if chats.last == nil || !chats.last!.isGPT {
                    withAnimation {
                        chats.append(ChatMessage(isGPT: true, content: response.content))
                    }
                } else {
                    chats[chats.count - 1].content = (chats.last?.content ?? "") + response.content
                }
                scrollPublisher.send()
            }
            } catch let error as GRPCStatus {
                displayErrorMessage(error.message ?? error.localizedDescription)
            } catch {
                displayErrorMessage(error.localizedDescription)
            }
            generating = false
        }
    }
}

#Preview {
    GPTView()
        .environmentObject(PDFViewModel())
        .frame(width: 300)
}
