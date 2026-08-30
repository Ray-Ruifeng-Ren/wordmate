import Foundation
import SwiftUI

/// 生词库 + 聊天记录的持久化存储(JSON 文件,存放于 Documents)
@MainActor
final class VocabStore: ObservableObject {
    @Published private(set) var words: [VocabWord] = []
    @Published private(set) var messages: [ChatMessage] = []

    private let wordsURL: URL
    private let messagesURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        wordsURL = docs.appendingPathComponent("vocab.json")
        messagesURL = docs.appendingPathComponent("chat.json")
        load()
    }

    // MARK: - 派生数据

    var activeWords: [VocabWord] {
        words.filter { !$0.isArchived }.sorted { $0.addedAt > $1.addedAt }
    }

    var archivedWords: [VocabWord] {
        words.filter { $0.isArchived }.sorted { ($0.archivedAt ?? $0.addedAt) > ($1.archivedAt ?? $1.addedAt) }
    }

    /// 待巩固的词:未归档,按查看次数少、加入时间早优先
    var dueWords: [VocabWord] {
        words.filter { !$0.isArchived }
            .sorted {
                if $0.viewCount != $1.viewCount { return $0.viewCount < $1.viewCount }
                return $0.addedAt < $1.addedAt
            }
    }

    // MARK: - 聊天

    func append(_ message: ChatMessage) {
        messages.append(message)
        if messages.count > 200 { messages.removeFirst(messages.count - 200) }
        saveMessages()
    }

    func clearChat() {
        messages.removeAll()
        saveMessages()
    }

    // MARK: - 生词库

    /// 查词成功后自动入库(按词条去重,重复则刷新释义)。返回是否为新词。
    @discardableResult
    func upsert(from result: LookupResult) -> Bool {
        let key = result.corrected.lowercased()
        if let idx = words.firstIndex(where: { $0.term.lowercased() == key }) {
            words[idx].meaningZh = result.meaningZh
            if words[idx].phonetic == nil { words[idx].phonetic = result.phonetic }
            if words[idx].partOfSpeech == nil { words[idx].partOfSpeech = result.partOfSpeech }
            if words[idx].examples.isEmpty { words[idx].examples = result.examples }
            saveWords()
            return false
        } else {
            words.append(VocabWord(from: result))
            saveWords()
            return true
        }
    }

    /// 点击「记住了」时调用;累计满阈值自动归档。返回本次是否触发了归档。
    @discardableResult
    func markRemembered(_ word: VocabWord) -> Bool {
        guard let idx = words.firstIndex(where: { $0.id == word.id }) else { return false }
        guard !words[idx].isArchived else { return false }
        words[idx].viewCount += 1
        var archivedNow = false
        if words[idx].viewCount >= VocabWord.archiveThreshold {
            words[idx].isArchived = true
            words[idx].archivedAt = Date()
            archivedNow = true
        }
        saveWords()
        return archivedNow
    }

    func restore(_ word: VocabWord) {
        guard let idx = words.firstIndex(where: { $0.id == word.id }) else { return }
        words[idx].isArchived = false
        words[idx].archivedAt = nil
        words[idx].viewCount = 0
        saveWords()
    }

    func delete(_ word: VocabWord) {
        words.removeAll { $0.id == word.id }
        saveWords()
    }

    // MARK: - 持久化

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = try? Data(contentsOf: wordsURL),
           let decoded = try? decoder.decode([VocabWord].self, from: data) {
            words = decoded
        }
        if let data = try? Data(contentsOf: messagesURL),
           let decoded = try? decoder.decode([ChatMessage].self, from: data) {
            messages = decoded
        }
    }

    private func saveWords() {
        save(words, to: wordsURL)
        NotificationManager.shared.rescheduleDaily(dueWords: dueWords)
    }

    private func saveMessages() {
        save(messages, to: messagesURL)
    }

    private func save<T: Encodable>(_ value: T, to url: URL) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(value) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
