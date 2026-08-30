import SwiftUI

/// 闪卡回顾:一次一张卡,自测后点「记住了 / 还没记住」跳下一张。
/// 「记住了」累计满阈值自动归档;「还没记住」的词排到本轮队尾再出现。
struct ReviewCardsView: View {
    @EnvironmentObject private var store: VocabStore
    @Environment(\.dismiss) private var dismiss
    @State private var queue: [UUID] = []
    @State private var revealed = false
    @State private var rememberedThisRound = 0
    @State private var archivedThisRound = 0
    @State private var initialized = false

    private var currentWord: VocabWord? {
        guard let id = queue.first else { return nil }
        return store.words.first { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let word = currentWord {
                    cardView(for: word)
                } else {
                    doneView
                }
            }
            .navigationTitle("生词回顾")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !queue.isEmpty {
                        Text("剩 \(queue.count) 张")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("退出") {
                        SpeechService.shared.stop()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            guard !initialized else { return }
            initialized = true
            queue = store.dueWords.map(\.id)
            speakCurrent()
        }
    }

    // MARK: - 卡片

    private func cardView(for word: VocabWord) -> some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 14) {
                Text(word.term)
                    .font(.system(size: 40, weight: .bold))
                if let phonetic = word.phonetic {
                    Text(phonetic)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                Button {
                    SpeechService.shared.speak(word.term)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)

                Divider().padding(.horizontal, 30)

                if revealed {
                    VStack(spacing: 10) {
                        HStack(spacing: 6) {
                            if let pos = word.partOfSpeech {
                                Text(pos)
                                    .font(.caption)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.12), in: Capsule())
                                    .foregroundStyle(Color.accentColor)
                            }
                            Text(word.meaningZh)
                                .font(.title3)
                        }
                        if let example = word.examples.first {
                            VStack(spacing: 3) {
                                Text(example.en).font(.subheadline)
                                Text(example.zh).font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    Button {
                        withAnimation { revealed = true }
                    } label: {
                        Label("显示释义", systemImage: "eye")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 36)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 20)

            Text("已记住 \(word.viewCount)/\(VocabWord.archiveThreshold) 次")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()

            HStack(spacing: 14) {
                Button {
                    forgot()
                } label: {
                    Label("还没记住", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(.orange)

                Button {
                    remembered()
                } label: {
                    Label("记住了", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var doneView: some View {
        VStack(spacing: 14) {
            Text("🎉")
                .font(.system(size: 60))
            Text("本轮回顾完成")
                .font(.title2.bold())
            Text("记住 \(rememberedThisRound) 次\(archivedThisRound > 0 ? ",\(archivedThisRound) 个词已归档" : "")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("完成") {
                SpeechService.shared.stop()
                dismiss()
            }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
        }
    }

    // MARK: - 动作

    private func remembered() {
        guard let word = currentWord else { return }
        rememberedThisRound += 1
        if store.markRemembered(word) {
            archivedThisRound += 1
        }
        advance(requeue: false)
    }

    private func forgot() {
        advance(requeue: true)
    }

    private func advance(requeue: Bool) {
        guard !queue.isEmpty else { return }
        let id = queue.removeFirst()
        if requeue {
            queue.append(id)
        }
        revealed = false
        speakCurrent()
    }

    private func speakCurrent() {
        guard SpeechService.autoSpeakEnabled, let word = currentWord else { return }
        SpeechService.shared.speak(word.term)
    }
}
