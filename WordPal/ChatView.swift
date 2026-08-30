import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var store: VocabStore
    @AppStorage("anthropicAPIKey") private var apiKey = ""
    @State private var input = ""
    @State private var isLoading = false
    @State private var showSettings = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messageList
                inputBar
            }
            .navigationTitle("Wordmate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if apiKey.isEmpty {
                        Text("演示模式")
                            .font(.caption2)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(.orange.opacity(0.15), in: Capsule())
                            .foregroundStyle(.orange)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if store.messages.isEmpty {
                        emptyHint
                    }
                    ForEach(store.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("查询中…").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .id("loading")
                    }
                }
                .padding(.vertical, 12)
            }
            .onChange(of: store.messages.count) { _, _ in
                if let lastID = store.messages.last?.id {
                    withAnimation { proxy.scrollTo(lastID, anchor: .bottom) }
                }
            }
            .onChange(of: isLoading) { _, loading in
                if loading { withAnimation { proxy.scrollTo("loading", anchor: .bottom) } }
            }
        }
    }

    private var emptyHint: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.bubble")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("发英文词,我回中文释义\n发中文词,我给英文表达\n拼错了也没关系,我会帮你猜")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("查过的词会自动进入生词库")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 80)
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("输入英文或中文词…", text: $input)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color(.systemGray6), in: Capsule())
                .focused($inputFocused)
                .submitLabel(.send)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit(send)
            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
            }
            .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(.bar)
    }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }
        input = ""
        store.append(ChatMessage(role: .user, text: text))
        isLoading = true
        let key = apiKey
        Task {
            do {
                let result = try await TranslationService.lookup(text, apiKey: key)
                store.upsert(from: result)
                store.append(ChatMessage(role: .assistant, result: result))
                if SpeechService.autoSpeakEnabled {
                    SpeechService.shared.speak(result.corrected)
                }
            } catch {
                store.append(ChatMessage(role: .assistant, text: error.localizedDescription))
            }
            isLoading = false
        }
    }
}

// MARK: - 气泡

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }
            Group {
                if let result = message.result {
                    ResultCard(result: result)
                } else {
                    Text(message.text ?? "")
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(
                            message.role == .user ? Color.accentColor : Color(.systemGray5),
                            in: RoundedRectangle(cornerRadius: 18)
                        )
                        .foregroundStyle(message.role == .user ? .white : .primary)
                }
            }
            if message.role == .assistant { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 12)
    }
}

/// 助手回复的查词卡片
struct ResultCard: View {
    let result: LookupResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if result.wasCorrected {
                Label("已从「\(result.original)」校正", systemImage: "wand.and.stars")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(result.corrected)
                    .font(.title2.bold())
                if let pos = result.partOfSpeech {
                    Text(pos)
                        .font(.caption)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                        .foregroundStyle(Color.accentColor)
                }
                Button {
                    SpeechService.shared.speak(result.corrected)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
            if let phonetic = result.phonetic {
                Text(phonetic)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(result.meaningZh)
                .font(.body)
            if !result.examples.isEmpty {
                Divider()
                ForEach(result.examples, id: \.en) { example in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(example.en).font(.subheadline)
                        Text(example.zh).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            if let note = result.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Label("已存入生词库", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        }
        .padding(14)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 18))
    }
}
