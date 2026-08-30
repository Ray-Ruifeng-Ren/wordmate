import SwiftUI

/// 单词详情页:纯查阅,不计数(记忆进度只在闪卡回顾里点「记住了」累积)
struct WordDetailView: View {
    @EnvironmentObject private var store: VocabStore
    let wordID: UUID

    private var word: VocabWord? {
        store.words.first { $0.id == wordID }
    }

    var body: some View {
        Group {
            if let word {
                content(for: word)
            } else {
                Text("该词已删除").foregroundStyle(.secondary)
            }
        }
        .task {
            // 等页面转场落定再读;返回时 task 自动取消,不会误杀下一个页面的朗读
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled, let word, SpeechService.autoSpeakEnabled else { return }
            SpeechService.shared.speak(word.term)
        }
    }

    private func content(for word: VocabWord) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(word.term).font(.largeTitle.bold())
                        Button {
                            SpeechService.shared.speak(word.term)
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                        if let pos = word.partOfSpeech {
                            Text(pos)
                                .font(.caption)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.accentColor.opacity(0.12), in: Capsule())
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    if let phonetic = word.phonetic {
                        Text(phonetic).font(.title3).foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("释义").font(.caption).foregroundStyle(.tertiary)
                    Text(word.meaningZh).font(.title3)
                }

                if !word.examples.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("例句").font(.caption).foregroundStyle(.tertiary)
                        ForEach(word.examples, id: \.en) { example in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(example.en).font(.body)
                                Text(example.zh).font(.subheadline).foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    if word.isArchived {
                        Label("已归档\(word.archivedAt.map { " · " + $0.formatted(date: .abbreviated, time: .omitted) } ?? "")", systemImage: "archivebox")
                            .font(.caption).foregroundStyle(.secondary)
                        Button {
                            store.restore(word)
                        } label: {
                            Label("移回生词库重新巩固", systemImage: "arrow.uturn.backward")
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Text("已记住 \(word.viewCount)/\(VocabWord.archiveThreshold) 次 · 加入于 \(word.addedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.top, 8)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(word.term)
        .navigationBarTitleDisplayMode(.inline)
    }
}
