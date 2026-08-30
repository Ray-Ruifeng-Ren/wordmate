# Wordmate 🐢

**Chat your way to a bigger English vocabulary.**

Wordmate is a chat-style English–Chinese dictionary app for iOS. Send an English word and get a Chinese definition card back; send a Chinese word and get the best English equivalent. Typos are fine — it guesses what you meant. Every word you look up is saved automatically, then drilled with flashcards until you know it.

## Features

- **Chat lookup** — English → Chinese definition, Chinese → English word, with phonetics, part of speech, and bilingual example sentences
- **Typo tolerance** — misspelled input is auto-corrected ("recieve" → *receive*), with the correction clearly labeled
- **Auto vocabulary book** — every looked-up word lands in your word list, deduplicated
- **Flashcard review** — see only the word first, test yourself, then tap **"I remember" / "Not yet"**; remember a word 5 times and it's archived for good, miss it and it comes back later in the round
- **Auto pronunciation** — each word is read aloud 3 times (on lookup, on card flip, on detail view), powered by on-device TTS
- **Daily reminders** — a local notification each morning with the words waiting for review; opening the app pops a review session too

## Lookup engine

- With an Anthropic API key (set in-app): full lookup via **Claude Haiku 4.5** — any word, any typo, fresh example sentences
- Without a key: a built-in demo dictionary (~40 common words) with prefix completion and edit-distance fuzzy matching
- Optional workspace ID field for identity-linked API keys

## Tech

SwiftUI (iOS 17+) · XcodeGen · AVSpeechSynthesizer · UserNotifications · JSON persistence (no backend, all data stays on device)

## Build

Requires full Xcode (not just Command Line Tools).

```bash
# regenerate the Xcode project after changing project.yml or adding files
xcodegen generate

# build for simulator
xcodebuild -project WordPal.xcodeproj -scheme WordPal \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Or just `open WordPal.xcodeproj` and hit ⌘R.

> Tip: keep derived data outside iCloud-synced folders (Desktop/Documents) — file-provider extended attributes break codesign.

## Project layout

```
WordPal/
  WordPalApp.swift        entry point, TabView, review popup on launch
  Models.swift            LookupResult / VocabWord / ChatMessage
  VocabStore.swift        JSON persistence (Documents/vocab.json, chat.json)
  TranslationService.swift Claude API call + lenient JSON parsing
  DemoDictionary.swift    offline demo dictionary + Levenshtein matching
  SpeechService.swift     3× auto pronunciation via AVSpeechSynthesizer
  NotificationManager.swift daily local notification
  ChatView.swift          chat UI + definition cards
  VocabView.swift         word list (active/archived) + search
  ReviewCardsView.swift   flashcard session
  WordDetailView.swift    word detail (reference only)
  SettingsView.swift      API key / workspace / reminder time / speech toggle
```

---

## 中文说明

聊天式英汉查词 + 生词库 iOS App:发英文回中文释义,发中文回英文表达,拼错自动校正;查过的词自动进生词库,闪卡自测("记住了"满 5 次自动归档,"还没记住"本轮稍后再现);查词与翻卡自动朗读 3 遍;每天定时推送待巩固生词,打开 App 即弹回顾。

查词引擎:App 设置里填入 Anthropic API Key 后由 Claude Haiku 4.5 提供全量查词;未配置时使用内置演示词典(约 40 词,支持模糊纠错)。所有数据仅存本机,无后端。
