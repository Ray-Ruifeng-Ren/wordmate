import Foundation
import UserNotifications

/// 每日生词回顾的本地推送
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    static let dailyIdentifier = "wordpal.daily.review"

    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "notifEnabled") as? Bool ?? true
    }

    var hour: Int {
        UserDefaults.standard.object(forKey: "notifHour") as? Int ?? 9
    }

    var minute: Int {
        UserDefaults.standard.object(forKey: "notifMinute") as? Int ?? 0
    }

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        return granted
    }

    /// 依据当前生词情况重排每日推送(生词库变化、设置变化时调用)
    func rescheduleDaily(dueWords: [VocabWord]) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyIdentifier])

        guard isEnabled, !dueWords.isEmpty else { return }

        let preview = dueWords.prefix(3).map(\.term).joined(separator: "、")
        let content = UNMutableNotificationContent()
        content.title = "今日生词回顾"
        content.body = "\(preview) 等 \(dueWords.count) 个生词等你回顾,记住满 \(VocabWord.archiveThreshold) 次自动归档 ✅"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: Self.dailyIdentifier, content: content, trigger: trigger)
        center.add(request)
    }
}
