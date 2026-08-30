import Foundation

/// 未配置 API Key 时的内置演示词典:支持拼写模糊匹配(编辑距离)与中→英反查
enum DemoDictionary {

    struct Entry {
        let term: String
        let phonetic: String
        let pos: String
        let zh: String
        let exampleEn: String
        let exampleZh: String
    }

    static func lookup(_ input: String) throws -> LookupResult {
        if TranslationService.containsChinese(input) {
            return try lookupChinese(input)
        }
        return try lookupEnglish(input)
    }

    private static func lookupEnglish(_ input: String) throws -> LookupResult {
        let key = input.lowercased()
        if let entry = entries.first(where: { $0.term == key }) {
            return result(from: entry, original: input, corrected: false)
        }
        // 前缀补全优先,其次编辑距离 ≤2 的最近词
        if let entry = entries.filter({ $0.term.hasPrefix(key) && key.count >= 3 })
            .min(by: { $0.term.count < $1.term.count }) {
            return result(from: entry, original: input, corrected: true)
        }
        let best = entries
            .map { (entry: $0, dist: levenshtein(key, $0.term)) }
            .min { $0.dist < $1.dist }
        if let best, best.dist <= 2 {
            return result(from: best.entry, original: input, corrected: true)
        }
        throw TranslationError.badResponse("演示词典未收录「\(input)」。在设置里填入 Anthropic API Key 可解锁全量查词。")
    }

    private static func lookupChinese(_ input: String) throws -> LookupResult {
        if let entry = entries.first(where: { $0.zh.contains(input) }) {
            return result(from: entry, original: input, corrected: false)
        }
        throw TranslationError.badResponse("演示词典未收录「\(input)」。在设置里填入 Anthropic API Key 可解锁全量查词。")
    }

    private static func result(from entry: Entry, original: String, corrected: Bool) -> LookupResult {
        LookupResult(
            corrected: entry.term,
            original: original,
            wasCorrected: corrected,
            phonetic: entry.phonetic,
            partOfSpeech: entry.pos,
            meaningZh: entry.zh,
            examples: [Example(en: entry.exampleEn, zh: entry.exampleZh)],
            note: "演示模式结果,配置 API Key 后可获得更全释义"
        )
    }

    private static func levenshtein(_ a: String, _ b: String) -> Int {
        let aChars = Array(a), bChars = Array(b)
        if aChars.isEmpty { return bChars.count }
        if bChars.isEmpty { return aChars.count }
        var prev = Array(0...bChars.count)
        var current = [Int](repeating: 0, count: bChars.count + 1)
        for i in 1...aChars.count {
            current[0] = i
            for j in 1...bChars.count {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                current[j] = min(prev[j] + 1, current[j - 1] + 1, prev[j - 1] + cost)
            }
            swap(&prev, &current)
        }
        return prev[bChars.count]
    }

    static let entries: [Entry] = [
        Entry(term: "apple", phonetic: "/ˈæp.əl/", pos: "n.", zh: "苹果", exampleEn: "She eats an apple every morning.", exampleZh: "她每天早上吃一个苹果。"),
        Entry(term: "ambitious", phonetic: "/æmˈbɪʃ.əs/", pos: "adj.", zh: "有雄心的;有抱负的", exampleEn: "He is ambitious about his career.", exampleZh: "他对自己的事业很有抱负。"),
        Entry(term: "achieve", phonetic: "/əˈtʃiːv/", pos: "v.", zh: "实现;达成", exampleEn: "She achieved her goal ahead of schedule.", exampleZh: "她提前实现了目标。"),
        Entry(term: "budget", phonetic: "/ˈbʌdʒ.ɪt/", pos: "n./v.", zh: "预算;做预算", exampleEn: "We need to stay within budget.", exampleZh: "我们需要控制在预算之内。"),
        Entry(term: "benefit", phonetic: "/ˈben.ɪ.fɪt/", pos: "n./v.", zh: "好处;受益", exampleEn: "Exercise benefits your health.", exampleZh: "运动有益健康。"),
        Entry(term: "collaborate", phonetic: "/kəˈlæb.ə.reɪt/", pos: "v.", zh: "合作;协作", exampleEn: "The two teams collaborate closely.", exampleZh: "两个团队紧密协作。"),
        Entry(term: "confident", phonetic: "/ˈkɒn.fɪ.dənt/", pos: "adj.", zh: "自信的;有把握的", exampleEn: "Be confident in the interview.", exampleZh: "面试时要自信。"),
        Entry(term: "deadline", phonetic: "/ˈded.laɪn/", pos: "n.", zh: "截止日期", exampleEn: "The deadline is next Friday.", exampleZh: "截止日期是下周五。"),
        Entry(term: "efficient", phonetic: "/ɪˈfɪʃ.ənt/", pos: "adj.", zh: "高效的", exampleEn: "This is a more efficient way to work.", exampleZh: "这是更高效的工作方式。"),
        Entry(term: "enthusiasm", phonetic: "/ɪnˈθjuː.zi.æz.əm/", pos: "n.", zh: "热情;热忱", exampleEn: "She showed great enthusiasm for the project.", exampleZh: "她对这个项目表现出极大热情。"),
        Entry(term: "feedback", phonetic: "/ˈfiːd.bæk/", pos: "n.", zh: "反馈", exampleEn: "Thanks for your feedback on the draft.", exampleZh: "感谢你对草稿的反馈。"),
        Entry(term: "flexible", phonetic: "/ˈflek.sə.bəl/", pos: "adj.", zh: "灵活的;有弹性的", exampleEn: "My schedule is flexible this week.", exampleZh: "我这周的日程比较灵活。"),
        Entry(term: "genuine", phonetic: "/ˈdʒen.ju.ɪn/", pos: "adj.", zh: "真诚的;真正的", exampleEn: "She has a genuine interest in helping others.", exampleZh: "她真心乐于助人。"),
        Entry(term: "grateful", phonetic: "/ˈɡreɪt.fəl/", pos: "adj.", zh: "感激的", exampleEn: "I'm grateful for your support.", exampleZh: "我很感激你的支持。"),
        Entry(term: "hesitate", phonetic: "/ˈhez.ɪ.teɪt/", pos: "v.", zh: "犹豫;迟疑", exampleEn: "Don't hesitate to ask questions.", exampleZh: "有问题尽管问,不要犹豫。"),
        Entry(term: "improve", phonetic: "/ɪmˈpruːv/", pos: "v.", zh: "改进;提高", exampleEn: "Practice will improve your English.", exampleZh: "练习会提高你的英语水平。"),
        Entry(term: "insight", phonetic: "/ˈɪn.saɪt/", pos: "n.", zh: "洞察;深刻理解", exampleEn: "The report offers useful insights.", exampleZh: "这份报告提供了有价值的洞察。"),
        Entry(term: "journey", phonetic: "/ˈdʒɜː.ni/", pos: "n.", zh: "旅程;历程", exampleEn: "Learning is a lifelong journey.", exampleZh: "学习是一生的旅程。"),
        Entry(term: "knowledge", phonetic: "/ˈnɒl.ɪdʒ/", pos: "n.", zh: "知识", exampleEn: "Knowledge is power.", exampleZh: "知识就是力量。"),
        Entry(term: "leverage", phonetic: "/ˈliː.vər.ɪdʒ/", pos: "v./n.", zh: "利用;杠杆", exampleEn: "We can leverage our data to make better decisions.", exampleZh: "我们可以利用数据做出更好的决策。"),
        Entry(term: "motivate", phonetic: "/ˈməʊ.tɪ.veɪt/", pos: "v.", zh: "激励;激发", exampleEn: "Good leaders motivate their teams.", exampleZh: "优秀的领导者会激励团队。"),
        Entry(term: "negotiate", phonetic: "/nəˈɡəʊ.ʃi.eɪt/", pos: "v.", zh: "谈判;协商", exampleEn: "We negotiated a better price.", exampleZh: "我们谈成了一个更好的价格。"),
        Entry(term: "opportunity", phonetic: "/ˌɒp.əˈtʃuː.nə.ti/", pos: "n.", zh: "机会;机遇", exampleEn: "This is a great opportunity to learn.", exampleZh: "这是一个很好的学习机会。"),
        Entry(term: "priority", phonetic: "/praɪˈɒr.ə.ti/", pos: "n.", zh: "优先事项;重点", exampleEn: "Quality is our top priority.", exampleZh: "质量是我们的首要任务。"),
        Entry(term: "quality", phonetic: "/ˈkwɒl.ə.ti/", pos: "n.", zh: "质量;品质", exampleEn: "We never compromise on quality.", exampleZh: "我们绝不在质量上妥协。"),
        Entry(term: "resilient", phonetic: "/rɪˈzɪl.i.ənt/", pos: "adj.", zh: "有韧性的;适应力强的", exampleEn: "Stay resilient in the face of setbacks.", exampleZh: "面对挫折要保持韧性。"),
        Entry(term: "schedule", phonetic: "/ˈʃedʒ.uːl/", pos: "n./v.", zh: "日程;安排", exampleEn: "Let's schedule a meeting for Monday.", exampleZh: "我们把会议安排在周一吧。"),
        Entry(term: "strategy", phonetic: "/ˈstræt.ə.dʒi/", pos: "n.", zh: "战略;策略", exampleEn: "We need a clear growth strategy.", exampleZh: "我们需要清晰的增长战略。"),
        Entry(term: "talent", phonetic: "/ˈtæl.ənt/", pos: "n.", zh: "天赋;人才", exampleEn: "She has a talent for languages.", exampleZh: "她有语言天赋。"),
        Entry(term: "unique", phonetic: "/juːˈniːk/", pos: "adj.", zh: "独特的;唯一的", exampleEn: "Everyone has a unique perspective.", exampleZh: "每个人都有独特的视角。"),
        Entry(term: "valuable", phonetic: "/ˈvæl.jə.bəl/", pos: "adj.", zh: "有价值的;宝贵的", exampleEn: "Your time is valuable.", exampleZh: "你的时间很宝贵。"),
        Entry(term: "wisdom", phonetic: "/ˈwɪz.dəm/", pos: "n.", zh: "智慧", exampleEn: "Experience brings wisdom.", exampleZh: "经验带来智慧。"),
        Entry(term: "negotiation", phonetic: "/nəˌɡəʊ.ʃiˈeɪ.ʃən/", pos: "n.", zh: "谈判;协商", exampleEn: "The negotiation lasted two hours.", exampleZh: "谈判持续了两个小时。"),
        Entry(term: "receive", phonetic: "/rɪˈsiːv/", pos: "v.", zh: "收到;接收", exampleEn: "Did you receive my email?", exampleZh: "你收到我的邮件了吗?"),
        Entry(term: "recommend", phonetic: "/ˌrek.əˈmend/", pos: "v.", zh: "推荐;建议", exampleEn: "Can you recommend a good book?", exampleZh: "你能推荐一本好书吗?"),
        Entry(term: "environment", phonetic: "/ɪnˈvaɪ.rən.mənt/", pos: "n.", zh: "环境", exampleEn: "We should protect the environment.", exampleZh: "我们应该保护环境。"),
        Entry(term: "experience", phonetic: "/ɪkˈspɪə.ri.əns/", pos: "n./v.", zh: "经验;经历;体验", exampleEn: "She has five years of experience.", exampleZh: "她有五年的工作经验。"),
        Entry(term: "communicate", phonetic: "/kəˈmjuː.nɪ.keɪt/", pos: "v.", zh: "沟通;交流", exampleEn: "We communicate mainly by email.", exampleZh: "我们主要通过邮件沟通。"),
        Entry(term: "decision", phonetic: "/dɪˈsɪʒ.ən/", pos: "n.", zh: "决定;决策", exampleEn: "It was a difficult decision to make.", exampleZh: "这是一个艰难的决定。"),
        Entry(term: "challenge", phonetic: "/ˈtʃæl.ɪndʒ/", pos: "n./v.", zh: "挑战", exampleEn: "Every challenge is a chance to grow.", exampleZh: "每个挑战都是成长的机会。")
    ]
}
