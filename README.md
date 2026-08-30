# 词伴 WordPal

聊天式英汉查词 + 生词库 iOS App。

## 功能

- **聊天查词**:发英文词回中文释义,发中文词回英文表达;拼写不准会自动猜测校正(卡片上标注"已从 xxx 校正")
- **生词库**:查过的词自动入库(按词条去重),含音标、词性、释义、双语例句;支持搜索、左滑删除
- **归档机制**:点开词条详情计一次"查看释义",满 5 次自动归档;归档词可一键移回重新巩固
- **推送回顾**:每天定时本地推送待巩固生词(时间可在设置里改);每次打开 App 弹出"今日生词回顾"(30 分钟冷却)

## 查词引擎

- 设置里填入 Anthropic API Key 后走 Claude(`claude-opus-5`,已带 server-side fallback)
- 未配置 Key 时用内置演示词典(约 40 个常用词,前缀补全 + 编辑距离 ≤2 模糊纠错)

## 构建

需要完整版 Xcode(App Store 安装),CommandLineTools 不够。

```bash
# 生成 Xcode 工程(仅 project.yml 变动后需要重新执行)
xcodegen generate

# 命令行构建到模拟器
xcodebuild -project WordPal.xcodeproj -scheme WordPal \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

或直接 `open WordPal.xcodeproj` 在 Xcode 里 ⌘R 运行。

## 结构

```
WordPal/
  WordPalApp.swift        入口 + TabView + 打开时回顾弹窗
  Models.swift            LookupResult / VocabWord / ChatMessage
  VocabStore.swift        JSON 持久化(Documents/vocab.json、chat.json)
  TranslationService.swift Claude API 调用 + 宽容 JSON 解析
  DemoDictionary.swift    演示词典 + Levenshtein 模糊匹配
  NotificationManager.swift 每日本地推送
  ChatView.swift          聊天页 + 查词卡片
  VocabView.swift         生词库(生词/归档分段 + 搜索)
  WordDetailView.swift    详情页(计数与自动归档发生在这里)
  ReviewSheet.swift       打开 App 时的回顾弹窗
  SettingsView.swift      API Key / 推送时间 / 清空聊天
```
