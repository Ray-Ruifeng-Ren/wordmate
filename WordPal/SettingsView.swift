import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: VocabStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("anthropicAPIKey") private var apiKey = ""
    @AppStorage("anthropicWorkspaceID") private var workspaceID = ""
    @AppStorage("notifEnabled") private var notifEnabled = true
    @AppStorage("autoSpeak") private var autoSpeak = true
    @AppStorage("notifHour") private var notifHour = 9
    @AppStorage("notifMinute") private var notifMinute = 0

    private var notifTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: notifHour, minute: notifMinute)) ?? Date()
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                notifHour = components.hour ?? 9
                notifMinute = components.minute ?? 0
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("sk-ant-…", text: $apiKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Workspace ID(wrkspc_…,可选)", text: $workspaceID)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .font(.subheadline)
                } header: {
                    Text("Anthropic API Key")
                } footer: {
                    Text(apiKey.isEmpty
                         ? "未配置时使用内置演示词典(约 40 个常用词,支持拼写纠错)。配置后由 Claude 提供全量查词、拼写猜测与例句。"
                         : "已启用 Claude 查词(claude-opus-5)。若报错提示需要 workspace-id,把 Console 里的 Workspace ID 填到第二栏。")
                }

                Section {
                    Toggle("查词后自动朗读 3 遍", isOn: $autoSpeak)
                } header: {
                    Text("发音")
                } footer: {
                    Text("查到词和打开词条详情时,自动用英语连读 3 遍;卡片上的 🔊 可随时重播。")
                }

                Section {
                    Toggle("每日生词提醒", isOn: $notifEnabled)
                    if notifEnabled {
                        DatePicker("提醒时间", selection: notifTime, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("推送")
                } footer: {
                    Text("每天按时提醒你回顾待巩固的生词;打开 App 时也会弹出回顾。")
                }

                Section {
                    Button("清空聊天记录", role: .destructive) {
                        store.clearChat()
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .onDisappear {
                NotificationManager.shared.rescheduleDaily(dueWords: store.dueWords)
            }
        }
    }
}
