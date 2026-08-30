import SwiftUI
import UserNotifications

@main
struct WordPalApp: App {
    @StateObject private var store = VocabStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .task {
                    _ = await NotificationManager.shared.requestAuthorization()
                    NotificationManager.shared.rescheduleDaily(dueWords: store.dueWords)
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var store: VocabStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var showReview = false
    @State private var lastReviewShownAt: Date? = nil

    var body: some View {
        TabView {
            ChatView()
                .tabItem { Label("聊天", systemImage: "bubble.left.and.bubble.right.fill") }
            VocabView()
                .tabItem { Label("生词库", systemImage: "books.vertical.fill") }
        }
        .sheet(isPresented: $showReview) {
            ReviewCardsView()
                .environmentObject(store)
        }
        .onAppear { maybeShowReview() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { maybeShowReview() }
        }
    }

    /// 每次打开 App 弹一次生词回顾(30 分钟冷却,避免频繁切换时反复弹)
    private func maybeShowReview() {
        guard !store.dueWords.isEmpty else { return }
        if let last = lastReviewShownAt, Date().timeIntervalSince(last) < 1800 { return }
        lastReviewShownAt = Date()
        showReview = true
    }
}
