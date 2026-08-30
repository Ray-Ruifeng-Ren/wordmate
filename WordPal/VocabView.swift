import SwiftUI

struct VocabView: View {
    @EnvironmentObject private var store: VocabStore
    @State private var segment = 0
    @State private var searchText = ""
    @State private var showReviewCards = false

    private var displayedWords: [VocabWord] {
        let source = segment == 0 ? store.activeWords : store.archivedWords
        guard !searchText.isEmpty else { return source }
        let query = searchText.lowercased()
        return source.filter {
            $0.term.lowercased().contains(query) || $0.meaningZh.contains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("分类", selection: $segment) {
                    Text("生词 \(store.activeWords.count)").tag(0)
                    Text("归档 \(store.archivedWords.count)").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 6)

                if segment == 0 && !store.activeWords.isEmpty {
                    Button {
                        showReviewCards = true
                    } label: {
                        Label("开始闪卡回顾", systemImage: "rectangle.on.rectangle.angled")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                }

                if displayedWords.isEmpty {
                    emptyState
                } else {
                    wordList
                }
            }
            .navigationTitle("生词库")
            .searchable(text: $searchText, prompt: "搜索单词或释义")
            .sheet(isPresented: $showReviewCards) {
                ReviewCardsView()
                    .environmentObject(store)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: segment == 0 ? "tray" : "archivebox")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text(segment == 0 ? "还没有生词\n去聊天页查词,会自动收进来" : "闪卡回顾中点「记住了」满 \(VocabWord.archiveThreshold) 次的词\n会自动归档到这里,不再出现")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Spacer()
        }
    }

    private var wordList: some View {
        List {
            ForEach(displayedWords) { word in
                NavigationLink(value: word.id) {
                    WordRow(word: word)
                }
            }
            .onDelete { offsets in
                for offset in offsets {
                    store.delete(displayedWords[offset])
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: UUID.self) { id in
            if let word = store.words.first(where: { $0.id == id }) {
                WordDetailView(wordID: word.id)
            }
        }
    }
}

struct WordRow: View {
    let word: VocabWord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(word.term).font(.headline)
                if let pos = word.partOfSpeech {
                    Text(pos).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                if !word.isArchived {
                    Text("\(word.viewCount)/\(VocabWord.archiveThreshold)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Text(word.meaningZh)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }
}
