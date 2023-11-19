//
//  GPTView.swift
//  PaperPilot
//
//  Created by 林思行 on 2023/11/11.
//

import SwiftUI
import Combine
import GRPC

struct GPTView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(PDFViewModel.self) private var pdfVM: PDFViewModel

    @AppStorage(AppStorageKey.User.username.rawValue)
    private var username = ""

    @State private var question = ""
    @State private var generating = false
    @State private var selectionEmpty = true
    @State private var chats = [ChatMessage]()
    @State private var keepContext = true
    @State private var currentContextId: String?
    @State private var remainingChat: Int32 = 1
    let scrollPublisher = PassthroughSubject<Void, Never>()

    var body: some View {
        ScrollViewReader { scrollView in
            List(chats) { chat in
                VStack(alignment: .leading, spacing: 8) {
                    if chat.isNewContext {
                        Label("Context cleared.", systemImage: "wand.and.stars")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(.separator)
                    }
                    HStack {
                        if chat.isGPT {
                            Image(ImageResource.openAI)
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
                            .textSelection(.enabled)
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
                    if let totalChat = chat.totalChat, let remainingChat = chat.remainingChat {
                        HStack {
                            Circle()
                                .foregroundStyle(indicatorColor(for: remainingChat))
                                .frame(width: 8, height: 8)
                            Text("\(remainingChat)/\(totalChat)")
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        }
                    }
                }
                .padding(.vertical, 8)
                .id(chat.id)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack {
                    if !selectionEmpty && !keepContext && currentContextId != nil {
                        HStack(spacing: 0) {
                            Image(systemName: "plus.bubble")
                                .foregroundStyle(Color.accentColor)
                                .padding(.trailing, 4)
                            Text("Will start a new chat from selection.")
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 4)
                            Button("Keep context") {
                                keepContext = true
                            }
                            .controlSize(.small)
                            .disabled(remainingChat == 0)
                        }
                        .font(.caption)
                    }
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
                    .animation(nil, value: selectionEmpty)
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
#if os(visionOS)
                    .clipShape(Capsule())
#else
                    .clipShape(RoundedRectangle(cornerRadius: 8))
#endif
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
            chats.append(ChatMessage.greeting(for: username))
            selectionEmpty = pdfVM.pdfView.currentSelection?.string == nil
            keepContext = selectionEmpty
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .PDFViewSelectionChanged)
                .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
        ) { _ in
            withAnimation(.easeOut) {
                selectionEmpty = pdfVM.pdfView.currentSelection?.string == nil
                keepContext = selectionEmpty
            }
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
        if remainingChat == 0 || !keepContext {
            currentContextId = nil
        }
        let request = Ai_GptRequest.with {
            if let currentSelection = pdfVM.pdfView.currentSelection?.string {
                $0.text = currentSelection
            }
            $0.action = action?.rawValue ?? question
            if let currentContextId = currentContextId {
                $0.chatID = currentContextId
            }
        }
        let myMessage = ChatMessage(isGPT: false,
                                    isNewContext: currentContextId == nil && chats.count > 1,
                                    content: action?.description ?? question,
                                    reference: pdfVM.pdfView.currentSelection?.string)
        pdfVM.pdfView.clearSelection()
        generating = true
        question = ""
        withAnimation {
            chats.append(myMessage)
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
                    if response.hasChatID {
                        currentContextId = response.chatID
                    }
                    remainingChat = response.remainChatTimes
                    withAnimation {
                        chats.append(ChatMessage(isGPT: true,
                                                 content: response.content,
                                                 totalChat: response.totalChatTimes,
                                                 remainingChat: response.remainChatTimes))
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

    func indicatorColor(for count: Int32) -> Color {
        switch count {
        case ...0: .red
        case 1...3: .orange
        case 10...: .green
        default: .green
        }
    }
}

#Preview {
    GPTView()
        .environment(PDFViewModel())
        .frame(width: 300)
}
