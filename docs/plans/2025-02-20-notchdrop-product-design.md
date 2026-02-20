# NotchDrop — Product Design Document

> **Date:** 2025-02-20
> **Status:** Draft — Pending Final Approval
> **Author:** Ricky (God of Monsters)

---

## 1. Product Overview

### One-Liner
你的 MacBook Notch，變成最快的收集入口。

### App Name
NotchDrop（暫定）

### Target Users
MacBook 使用者，日常需要快速捕捉靈感、待辦、暫存檔案的人。特別適合經常開視訊會議、需要一邊看鏡頭一邊記筆記的遠端工作者。

### Core Value Proposition
- **零摩擦** — Hover 即開，拖放即存，不打斷任何工作流
- **視訊友善** — 筆記區就在鏡頭旁邊，記筆記 = 看著對方
- **美到捨不得關** — Metal GPU 渲染的流暢液態動畫，同類 App 中最精緻

### Platform
macOS (Swift + SwiftUI + AppKit + Metal)

---

## 2. Core Features (V1)

### 2.1 Quick Todo
- 展開 Notch → 輸入框打字 → `Enter` 存成 Todo
- Todo 可標記完成 (isDone)
- 最近未完成的 Todo 顯示在展開介面

### 2.2 Quick Note
- 展開 Notch → 輸入框打字 → `⌘+Enter` 存成筆記
- 筆記支援多行文字
- 最近筆記顯示在展開介面

### 2.3 File Shelf（檔案暫存）
- 拖曳檔案到 Notch 區域 → 自動亮起接收區 → 放開即存
- 檔案以縮圖形式顯示在展開介面
- 點擊暫存檔案可開啟 / 拖出到其他 App
- 檔案存為副本，不動原檔

### 2.4 AI Assistant（Pro only — BYOK）
- 用戶自帶 API key（Bring Your Own Key）
- App 直接從用戶端打 API，資料不經過我們的伺服器
- 支援 Provider：OpenAI (GPT)、Anthropic (Claude)，架構可擴充

**V1 AI 功能：**
- **整理筆記** — 選取多筆 Note → AI 合併成有結構的摘要
- **從筆記提取 Todo** — AI 讀筆記後建議「這些應該變成 Todo」
- **快速摘要** — 長段筆記一鍵濃縮成重點

**觸發方式：** 展開介面的 Notes/Todos tab 中，提供 AI 操作按鈕（例如 ✦ 圖示）

**未來可擴充（V2+）：** 自動分類、智慧搜尋、多語翻譯、Ollama 本地模型支援

---

## 3. Interaction Design

### 3.1 Three States

**State 1: Invisible（99% of the time）**
- Notch 區域完全原生外觀
- 不吃資源、不干擾

**State 2: Hover Expand**
- 滑鼠移到 Notch 區域 → Notch 往下「滑開」展開
- 展開後顯示：
  - 輸入框（Enter = Todo, ⌘+Enter = Note）
  - 最近收集列表（Todo / Note 縮覽）
  - 檔案暫存格（縮圖）
- 滑鼠移開 → 動畫收回，恢復隱形

**State 3: Drag Sensing**
- 系統偵測到拖曳檔案中 → Notch 自動亮起接收區
- 放開檔案 → 吸入動畫 → 暫存完成
- 鬆手或拖走 → 接收區消失

### 3.2 Expand Animation Concept
- Metal shader 渲染「液態金屬」效果
- 展開：液態金屬從 Notch 流淌下來，形成操作介面
- 收合：介面流回 Notch，消失
- 整個過程流暢、有機、有質感

---

## 4. Data Architecture

### 4.1 Data Types

| Type | Storage | Fields |
|------|---------|--------|
| **Todo** | SQLite (GRDB) | id, content, isDone, createdAt, updatedAt |
| **Note** | SQLite (GRDB) | id, content, createdAt, updatedAt |
| **File** | Local folder + SQLite index | id, originalName, storedPath, fileSize, thumbnail, createdAt |

### 4.2 File Storage
- Default path: `~/Library/Application Support/NotchDrop/files/`
- User can customize storage path in Settings
- Files are copied (not moved) — originals untouched

### 4.3 Data Lifecycle
- Todo completed → marked isDone, retained permanently
- Notes → retained permanently
- Files → user manually retrieves or deletes (no auto-cleanup)
- All user data belongs to the user — never auto-deleted, even on free plan

---

## 5. Business Model

### 5.1 Freemium + One-Time Purchase

**Price: $4.99 USD (one-time buy)**

| Feature | Free | Pro ($4.99) |
|---------|------|-------------|
| Active (incomplete) Todos | Max 10 | Unlimited |
| Notes | Max 10 | Unlimited |
| File Shelf | Max 15 files | Unlimited |
| Metal shader animations | Yes | Yes |
| Notch themes | 1 default | Multiple themes |
| AI Assistant (BYOK) | No | Yes (user provides own API key) |

### 5.2 Free Plan Limits — Philosophy
- Hitting limit → cannot add new items via app
- Existing data is **fully preserved**, viewable, editable, deletable
- User deletes old items → can add new ones
- Completed Todos do NOT count toward free limit
- **Principle: Data belongs to user. Free plan limits functionality, never data.**

### 5.3 Implementation
- StoreKit 2 (same as MenuBarCalendar experience)
- Non-consumable in-app purchase

---

## 6. Technical Architecture

### 6.1 Tech Stack

| Layer | Choice | Reason |
|-------|--------|--------|
| Language | Swift 5 | Existing expertise |
| UI | SwiftUI + AppKit | SwiftUI for content, AppKit for window control |
| Animation | Metal (MTKView) | Core differentiator — liquid metal animations |
| Database | GRDB (SQLite) | Lightweight, Swift-friendly |
| File Mgmt | FileManager | Native macOS |
| Drag Detection | NSEvent global monitor + NSDraggingDestination | System-level drag event detection |
| Payments | StoreKit 2 | Proven in MenuBarCalendar |
| Window | NSPanel (.nonactivating) | Critical: doesn't steal focus |
| AI | URLSession → OpenAI / Anthropic API | BYOK, zero server cost, direct from client |
| API Key Storage | Keychain | Secure, native macOS credential storage |

### 6.2 App Architecture

```
NotchDrop App
├── AppDelegate
│   ├── NotchWindowController    ← Notch overlay window
│   └── SettingsWindowController ← Settings window
├── Core
│   ├── NotchDetector            ← Detect Notch position & size
│   ├── HoverMonitor             ← Global mouse tracking
│   ├── DragMonitor              ← Global drag detection
│   └── MetalAnimationView       ← Liquid metal animation renderer
├── Features
│   ├── TodoManager              ← Todo CRUD
│   ├── NoteManager              ← Note CRUD
│   ├── FileShelfManager         ← File shelf management
│   ├── ProManager               ← Free/Pro quota control
│   └── AIService                ← BYOK AI integration
│       ├── AIProviderProtocol   ← Common interface
│       ├── OpenAIProvider       ← GPT API
│       ├── AnthropicProvider    ← Claude API
│       └── AIKeyManager         ← Keychain storage for API keys
├── Data
│   ├── DatabaseManager (GRDB)   ← SQLite operations
│   └── FileStorageManager       ← File system operations
└── Views (SwiftUI)
    ├── NotchExpandedView        ← Main expanded interface
    ├── TodoListView             ← Todo list
    ├── NoteListView             ← Note list
    ├── FileShelfView            ← File shelf grid
    └── SettingsView             ← Settings page
```

### 6.3 Key Technical Challenges

1. **Notch Positioning** — Use `NSScreen.main?.auxiliaryTopLeftArea` or calculate screen top-center to precisely overlay a transparent window on the Notch
2. **Non-Activating Window** — `NSPanel` with `.nonactivating` style to avoid stealing focus from user's current app
3. **Global Drag Detection** — Monitor system-wide drag events to light up the drop zone
4. **Metal Animation** — Liquid metal expand/collapse shader (leverage MenuBarCalendar experience)

---

## 7. Competitive Landscape

| App | Focus | NotchDrop Advantage |
|-----|-------|---------------------|
| Boring Notch | Music control, file shelf, open source | Superior animation quality, dedicated productivity focus |
| Alcove | Dynamic Island widgets | Not just cosmetic — real quick-capture functionality |
| Notchmeister | Visual effects only | Functional + beautiful, not just eye candy |
| TopNotch | Hide the notch | Embrace the notch, make it useful |
| DropNotch | File drag & drop only | Full quick-capture suite (Todo + Note + File) |
| FocusNotch | Pomodoro timer | Different use case — capture vs. focus |

### NotchDrop's Unique Position
No existing app combines **quick Todo + Note + File capture** with **Metal-rendered premium animations** in the Notch area. The "look at camera while taking notes" angle is completely unaddressed.

---

## 8. V1 Scope — What We Ship

### In Scope
- [ ] Notch detection & overlay window
- [ ] Hover expand / collapse with Metal liquid animation
- [ ] Drag-to-Notch file capture with sensing animation
- [ ] Quick Todo input (Enter)
- [ ] Quick Note input (⌘+Enter)
- [ ] File shelf with thumbnails
- [ ] SQLite local storage (GRDB)
- [ ] Custom file storage path in Settings
- [ ] Free/Pro tier with StoreKit 2
- [ ] Settings window (storage path, theme, about)
- [ ] AI Assistant: Summarize notes (Pro + BYOK)
- [ ] AI Assistant: Extract todos from notes (Pro + BYOK)
- [ ] AI Assistant: Quick note summary (Pro + BYOK)
- [ ] AI Settings: Provider selection (OpenAI / Anthropic)
- [ ] AI Settings: API key input (stored in Keychain)

### Out of Scope (Future)
- Third-party integrations (Apple Reminders, Todoist, Obsidian)
- iCloud sync
- Keyboard shortcut to expand
- Multiple Notch themes (Pro feature — ship with 1 default first)
- Search within collected items
- Widget / menu bar companion
- AI: Auto-categorization, smart search, translation
- AI: Ollama / local model support
- AI: Additional providers (Gemini, Mistral, etc.)

---

## 9. Success Metrics

| Metric | Target |
|--------|--------|
| App Store rating | 4.5+ stars |
| Free → Pro conversion | 10%+ |
| Daily active usage | 5+ captures per day per user |
| App Store feature | "Great Apps for Mac" consideration |
