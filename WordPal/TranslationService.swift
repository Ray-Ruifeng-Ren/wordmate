import Foundation

enum TranslationError: LocalizedError {
    case emptyInput
    case badResponse(String)
    case refused

    var errorDescription: String? {
        switch self {
        case .emptyInput: return "请输入一个英文单词或中文词"
        case .badResponse(let detail): return "查询失败:\(detail)"
        case .refused: return "这条请求被安全策略拒绝了,换个词试试"
        }
    }
}

enum TranslationService {

    /// 查词入口:有 API Key 走 Claude,否则走内置演示词典
    static func lookup(_ rawInput: String, apiKey: String) async throws -> LookupResult {
        let input = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { throw TranslationError.emptyInput }

        if apiKey.isEmpty {
            return try DemoDictionary.lookup(input)
        }
        return try await lookupViaClaude(input, apiKey: apiKey)
    }

    static func containsChinese(_ text: String) -> Bool {
        text.unicodeScalars.contains { (0x4E00...0x9FFF).contains($0.value) }
    }

    // MARK: - Claude API

    private static let systemPrompt = """
    你是一个英汉双向词汇助手。用户每次发来一条内容,只有两种情况:
    1. 英文单词或短语(拼写可能不准确)
    2. 中文词或短语

    你的任务:
    - 英文输入:如果拼写有误或不完整,先猜测用户最可能想查的词并校正;给出中文释义。
    - 中文输入:给出最贴切、最常用的英文对应词。
    - 无论哪个方向,corrected 字段永远填英文词条(小写,专有名词除外)。

    只输出一个 JSON 对象,不要任何其他文字、不要 markdown 代码块。字段:
    {
      "corrected": "校正后的英文词条",
      "original": "用户原始输入",
      "wasCorrected": true/false(是否做了拼写校正或猜测),
      "phonetic": "美式音标,如 /ˈæp.əl/",
      "partOfSpeech": "词性缩写,如 n. / v. / adj.,多词性用分号分隔",
      "meaningZh": "简洁的中文释义,多义项用分号分隔,控制在 60 字内",
      "examples": [
        {"en": "英文例句1", "zh": "对应中文翻译"},
        {"en": "英文例句2", "zh": "对应中文翻译"}
      ],
      "note": "可选:近义词辨析或用法提示,一句话;没有就填 null"
    }

    例句给 2 条,贴近日常与职场场景。如果输入完全无法识别为词汇,corrected 填空字符串,note 里说明。
    """

    private static func lookupViaClaude(_ input: String, apiKey: String) async throws -> LookupResult {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        // 身份关联型 API Key 需要指明 workspace
        let workspaceID = UserDefaults.standard.string(forKey: "anthropicWorkspaceID")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !workspaceID.isEmpty {
            request.setValue(workspaceID, forHTTPHeaderField: "anthropic-workspace-id")
        }

        let body: [String: Any] = [
            "model": "claude-haiku-4-5",
            "max_tokens": 1000,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": input]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw TranslationError.badResponse("无网络响应")
        }
        guard http.statusCode == 200 else {
            let detail = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                .flatMap { $0["error"] as? [String: Any] }
                .flatMap { $0["message"] as? String }
            throw TranslationError.badResponse(detail ?? "HTTP \(http.statusCode)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TranslationError.badResponse("响应不是 JSON")
        }
        if let stopReason = json["stop_reason"] as? String, stopReason == "refusal" {
            throw TranslationError.refused
        }
        guard let content = json["content"] as? [[String: Any]],
              let text = content.first(where: { ($0["type"] as? String) == "text" })?["text"] as? String else {
            throw TranslationError.badResponse("响应缺少文本内容")
        }

        return try parseResult(from: text, original: input)
    }

    /// 宽容解析:剥掉可能出现的 ```json 围栏,截取首个 { 到末个 }
    private static func parseResult(from text: String, original: String) throws -> LookupResult {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let start = cleaned.firstIndex(of: "{"), let end = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[start...end])
        }
        guard let data = cleaned.data(using: .utf8) else {
            throw TranslationError.badResponse("编码错误")
        }
        do {
            var result = try JSONDecoder().decode(LookupResult.self, from: data)
            if result.original.isEmpty { result.original = original }
            guard !result.corrected.isEmpty else {
                throw TranslationError.badResponse(result.note ?? "无法识别这个词")
            }
            return result
        } catch let error as TranslationError {
            throw error
        } catch {
            throw TranslationError.badResponse("解析结果失败")
        }
    }
}
