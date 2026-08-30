import Foundation

// MARK: - 词条

struct Example: Codable, Equatable, Hashable {
    var en: String
    var zh: String
}

/// 一次查词的结果(来自 Claude API 或演示词典)
struct LookupResult: Codable, Equatable {
    /// 校正后的英文词(输入中文时为最贴切的英文对应词)
    var corrected: String
    /// 用户原始输入
    var original: String
    /// 是否做了拼写校正
    var wasCorrected: Bool
    var phonetic: String?
    var partOfSpeech: String?
    /// 中文释义
    var meaningZh: String
    var examples: [Example]
    /// 额外说明(近义词、用法提示等,可空)
    var note: String?
}

/// 生词库中的一个词
struct VocabWord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    /// 英文词条(统一小写作为去重键,展示用原样)
    var term: String
    var phonetic: String?
    var partOfSpeech: String?
    var meaningZh: String
    var examples: [Example]
    var addedAt: Date = Date()
    /// 点击「记住了」的累计次数,达到阈值自动归档(字段名保留 viewCount 以兼容已存数据)
    var viewCount: Int = 0
    var isArchived: Bool = false
    var archivedAt: Date?

    static let archiveThreshold = 5

    init(from result: LookupResult) {
        self.term = result.corrected
        self.phonetic = result.phonetic
        self.partOfSpeech = result.partOfSpeech
        self.meaningZh = result.meaningZh
        self.examples = result.examples
    }
}

// MARK: - 聊天消息

enum ChatRole: String, Codable {
    case user
    case assistant
}

struct ChatMessage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var role: ChatRole
    /// 纯文本(用户消息,或助手的错误/提示文本)
    var text: String?
    /// 助手的查词卡片
    var result: LookupResult?
    var timestamp: Date = Date()
}
