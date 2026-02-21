# NotchDrop — App Store Submission Package
> 送審材料包。你只需要把以下內容複製貼上到 App Store Connect 對應欄位。

---

## 🚀 快速送審步驟（你只需要做這些）

### Step 1：Xcode 建立 Archive 並上傳
1. 打開 Xcode → 選擇 `NotchDrop` target
2. 選擇 `Product` → `Archive`
3. Archive 完成後 → `Distribute App` → `App Store Connect` → `Upload`
4. 等待 Processing 完成（約 5–10 分鐘）

### Step 2：App Store Connect 填寫資料
前往 [App Store Connect](https://appstoreconnect.apple.com) → 你的 App → App Store → 填寫：

| 欄位 | 來源 |
|------|------|
| App Name | 見下方 🇺🇸 EN / 🇹🇼 ZH-TW 區塊 |
| Subtitle | 見下方 |
| Description | 見下方 |
| Keywords | 見下方 |
| What's New | 見下方 |
| App Icon | `AppStoreSubmission/AppIcon_1024x1024.png` |
| Screenshots | `AppStoreScreenshots/en/` × 5 + `AppStoreScreenshots/zh-TW/` × 5 |
| Privacy Policy URL | `https://lafcadio5th.github.io/NotchDrop/privacy.html` |
| Support URL | `https://lafcadio5th.github.io/NotchDrop/` |
| Review Notes | 見下方 👨‍💻 REVIEW INFORMATION 區塊 |

### Step 3：建立 In-App Purchase
App Store Connect → In-App Purchases → `+` → Non-Consumable：

| 欄位 | 值 |
|------|-----|
| Product ID | `com.kelvintan.NotchDrop.pro` |
| Reference Name | `NotchDrop Pro` |
| Price | Tier 5 → $4.99 |
| Display Name (EN) | `NotchDrop Pro` |
| Description (EN) | 見下方 💰 IAP 區塊 |
| Display Name (ZH-TW) | `NotchDrop Pro` |
| Description (ZH-TW) | 見下方 💰 IAP 區塊 |

### Step 4：App Privacy
App Store Connect → App Privacy → 選擇「No, we do not collect data from this app」

### Step 5：選擇 Build 並送審
App Store Connect → App Store → Build → 選擇剛上傳的 Build → `Submit for Review`

---

## ═══════════════════════════════════════
## 🇺🇸 ENGLISH (Primary Language)
## ═══════════════════════════════════════

### App Name (30 chars max)
```
NotchDrop
```

### Subtitle (30 chars max)
```
Notch Todos, Notes & Files
```

### Keywords (100 chars max, comma-separated)
```
notch,todo,notes,file shelf,productivity,menubar,quick capture,macbook,widget,clipboard
```

### Description (4000 chars max)
```
NotchDrop turns your MacBook's notch into a powerful productivity hub — always one hover away, zero dock footprint.

WHAT IT DOES
Hover over the notch to instantly reveal your todos, notes, and a file shelf. The panel expands smoothly from the notch itself using a GPU-accelerated Liquid Metal animation, then disappears just as elegantly when you move away.

QUICK TODOS
Capture tasks in under a second. Type your todo and press Enter — it's saved instantly. Come back to check items off without ever switching apps. Perfect for those thoughts that strike mid-meeting.

MEETING NOTES
The notch sits right above your camera. During video calls, glance at your notes while keeping eye contact with your team. Press ⌘Enter to save a note instantly, timestamped and always accessible.

FILE SHELF
Drag any file to the notch while dragging it across your desktop. It parks there safely until you need it. Drag it back out to drop into any app. The ultimate cross-app clipboard for files.

AI SUMMARIZE (Pro)
Connect your own OpenAI or Anthropic API key to let AI summarize your meeting notes into action items — with complete privacy. Your notes go directly from your Mac to your chosen AI provider. We never see them.

LIQUID METAL ANIMATION
The notch doesn't just expand — it morphs. A custom Metal GPU shader animates the notch shape as it grows and collapses, creating a silky smooth effect that feels native to macOS.

COMPLETELY INVISIBLE
No dock icon. No menu bar icon cluttering your status bar. NotchDrop is invisible until you hover over the notch. It launches at login and stays out of your way until you need it.

FREE & PRO
Free tier is genuinely useful: 10 todos, 10 notes, 15 files. Upgrade to Pro with a one-time $4.99 purchase for unlimited everything plus AI features.

PRIVACY FIRST
Everything stays on your Mac. No accounts, no servers, no telemetry. AI features use your own API key stored securely in your Mac's Keychain — we never touch your data.

REQUIRES
• MacBook with notch (MacBook Pro 2021 or later, MacBook Air 2022 or later)
• macOS 14 Sonoma or later
```

### What's New (Version 1.0)
```
Welcome to NotchDrop!

First release. Turn your MacBook notch into a productivity hub with quick todos, meeting notes, a file shelf, and optional AI summarization. All powered by a smooth Liquid Metal animation.
```

---

## ═══════════════════════════════════════
## 🇹🇼 繁體中文 (Traditional Chinese)
## ═══════════════════════════════════════

### App 名稱（最多 30 字元）
```
NotchDrop
```

### 副標題（最多 30 字元）
```
瀏海待辦、筆記與檔案管理
```

### 關鍵字（最多 100 字元，以逗號分隔）
```
瀏海,待辦,筆記,檔案,生產力,快速記錄,MacBook,工具列,剪貼板,會議
```

### 描述（最多 4000 字元）
```
NotchDrop 將你 MacBook 的瀏海變成強大的生產力中樞——懸停即開，不佔 Dock 空間。

功能介紹
懸停到瀏海，立即展開待辦清單、筆記和檔案暫存架。展開動畫由 GPU 加速的液態金屬特效驅動，移開滑鼠後優雅收合，完全不打擾你的工作流程。

快速待辦
不到一秒記錄任務。輸入待辦內容，按 Enter 即儲存。回來勾選完成項目，全程不需切換 App。最適合開會時突然閃現的待辦想法。

會議筆記
瀏海就在鏡頭正上方。視訊會議中，瞄一眼筆記的同時依然保持與對方的視線接觸。按 ⌘Enter 立即儲存筆記，自動加上時間戳記。

檔案暫存架
拖曳任何檔案到瀏海暫時存放。等你需要時再拖出來，放進任何 App。最完美的跨 App 檔案中繼站。

AI 摘要（Pro）
連接你自己的 OpenAI 或 Anthropic API 金鑰，讓 AI 將會議筆記整理成行動清單——完全私密。你的筆記直接從你的 Mac 傳送給你選擇的 AI 服務，我們完全看不到。

液態金屬動畫
瀏海不只是展開——它會變形。客製化的 Metal GPU 著色器在瀏海展開和收合時製造流暢的形狀變形效果，原生 macOS 質感。

完全隱形
無 Dock 圖示，不佔用選單列空間。NotchDrop 隱形存在，直到你懸停到瀏海。登入即啟動，不打擾不存在。

免費與 Pro
免費版真的夠用：10 個待辦、10 則筆記、15 個暫存檔案。以一次性 $4.99 美元升級 Pro，享有無限數量加上 AI 功能。

隱私優先
所有資料留在你的 Mac 上。無需帳號，無伺服器，無追蹤。AI 功能使用你自己的 API 金鑰，安全儲存在 Mac 鑰匙圈——我們從不接觸你的資料。

系統需求
• 配備瀏海的 MacBook（MacBook Pro 2021 年後、MacBook Air 2022 年後）
• macOS 14 Sonoma 或更新版本
```

### 最新消息（版本 1.0）
```
歡迎使用 NotchDrop！

首次發布。將你的 MacBook 瀏海變成生產力中樞，提供快速待辦、會議筆記、檔案暫存架，以及可選的 AI 摘要功能。全程搭配流暢的液態金屬動畫。
```

---

## ═══════════════════════════════════════
## ⚙️ APP INFORMATION（通用設定）
## ═══════════════════════════════════════

### Bundle ID
```
com.kelvintan.NotchDrop.NotchDrop
```

### SKU（自訂，唯一識別碼）
```
notchdrop-macos-2025
```

### Version
```
1.0
```

### Build
```
1
```

### Category（主分類）
```
Productivity
```

### Secondary Category（次分類）
```
Utilities
```

### Content Rating
```
4+（無限制內容）
```

### Price
```
Free（App 本身免費）
```

---

## ═══════════════════════════════════════
## 💰 IN-APP PURCHASE（應用內購買）
## ═══════════════════════════════════════

### Product ID
```
com.kelvintan.NotchDrop.pro
```

### Reference Name（內部用，不公開）
```
NotchDrop Pro
```

### Type
```
Non-Consumable（一次性購買）
```

### Price
```
Tier 1 → $0.99 USD
（建議改為 Tier 5 → $4.99 USD）
```

### Display Name（EN）
```
NotchDrop Pro
```

### Description（EN）
```
Unlock unlimited todos, notes, and file shelf. Plus AI-powered note summarization with your own API key.
```

### Display Name（ZH-TW）
```
NotchDrop Pro
```

### Description（ZH-TW）
```
解鎖無限待辦、筆記與檔案暫存架，並啟用 AI 筆記摘要功能（需自備 API 金鑰）。
```

---

## ═══════════════════════════════════════
## 👨‍💻 REVIEW INFORMATION（審核資訊）
## ═══════════════════════════════════════

### Review Notes（給 Apple 審核員的說明）
```
Thank you for reviewing NotchDrop.

IMPORTANT — NOTCH REQUIREMENT:
This app requires a MacBook with a notch (MacBook Pro 2021 or later, MacBook Air 2022 or later). The app detects the notch area and places a floating panel there. On Macs without a notch, the app will not function as intended.

If testing on a Mac without a notch, the panel will appear at the top-center of the screen instead of the notch area.

HOW TO TEST THE CORE FEATURES:
1. Launch the app — no dock icon will appear (this is by design)
2. Move your cursor to the top-center of the screen (notch area)
3. The panel will expand smoothly — you'll see the Todo/Notes/Files tabs
4. Type something in the input field and press Enter to save a todo
5. Press ⌘Enter to save as a note instead
6. Drag any file from Finder onto the notch panel to add it to the file shelf

PRO FEATURES / IN-APP PURCHASE:
To test Pro features, you can use the free tier limits to see the upgrade prompt. The IAP is a one-time purchase of $4.99 USD. Sandbox testing credentials are not required — standard App Store review process applies.

AI FEATURES (Pro only):
The AI summarization requires the user to provide their own OpenAI or Anthropic API key in Settings → AI. We do not provide API keys. This feature is not required for core app functionality.

PRIVACY:
The app uses NSPasteboardUsageDescription for drag-and-drop file detection. No data is collected or transmitted except when the user explicitly uses AI features with their own API key.

There are no login flows, no accounts, and no network requests except to third-party AI APIs (user-initiated, with user's own key).
```

### Demo Account
```
Not required — no login or account needed.
```

### Contact Information
```
Email: support@notchdrop.app
```

---

## ═══════════════════════════════════════
## 🔒 APP PRIVACY（隱私標籤）
## ═══════════════════════════════════════

在 App Store Connect → App Privacy 填寫：

### Data Collection
```
選擇：「No, we do not collect data from this app」
（此 App 不收集任何用戶資料）
```

但需要聲明 Third-party SDK 的資料使用：
- StoreKit（Apple 負責，無需額外聲明）

---

## ═══════════════════════════════════════
## 📸 SCREENSHOTS CHECKLIST
## ═══════════════════════════════════════

截圖路徑：/AppStoreScreenshots/en/ 和 /zh-TW/

✅ 已驗證：所有截圖尺寸為 2560×1600（= 1280×800 @2x Retina，符合 Mac App Store 要求）

| # | 檔名 | 尺寸 | 內容 |
|---|------|------|------|
| 1 | 01_en.png / 01_zh-TW.png | 2560×1600 ✅ | Todos — 主視覺 |
| 2 | 02_en.png / 02_zh-TW.png | 2560×1600 ✅ | Notes — 會議筆記 |
| 3 | 03_en.png / 03_zh-TW.png | 2560×1600 ✅ | Files — 檔案暫存架 |
| 4 | 04_en.png / 04_zh-TW.png | 2560×1600 ✅ | AI 摘要 |
| 5 | 05_en.png / 05_zh-TW.png | 2560×1600 ✅ | Hover / Drag |

### App Icon

✅ 已驗證：`AppStoreSubmission/AppIcon_1024x1024.png`（1024×1024，無 Alpha 通道）

---

## ═══════════════════════════════════════
## ✅ 送審前最終確認清單
## ═══════════════════════════════════════

### App Store Connect 設定（你需要手動貼上的部分）
- [ ] App 名稱已填寫（EN + ZH-TW）← 貼上本文件上方的文字
- [ ] Subtitle 已填寫（EN + ZH-TW）← 貼上本文件上方的文字
- [ ] Description 已填寫（EN + ZH-TW）← 貼上本文件上方的文字
- [ ] Keywords 已填寫（EN + ZH-TW）← 貼上本文件上方的文字
- [ ] What's New 已填寫 ← 貼上本文件上方的文字
- [ ] 截圖已上傳（5 張 EN + 5 張 ZH-TW）← 檔案在 /AppStoreScreenshots/ ✅ 尺寸已驗證
- [ ] App Icon 已上傳 ← 使用 AppStoreSubmission/AppIcon_1024x1024.png ✅ 已驗證無 Alpha
- [ ] Category 已設定（Productivity）
- [ ] Age Rating 已設定（4+）
- [ ] Privacy Policy URL 已填寫 ← 見下方

### Privacy Policy URL
```
https://lafcadio5th.github.io/NotchDrop/privacy.html
```

### Support URL
```
https://lafcadio5th.github.io/NotchDrop/
```

### Marketing URL（可選）
```
https://lafcadio5th.github.io/NotchDrop/
```

### In-App Purchase
- [ ] Pro IAP 已在 App Store Connect 建立
- [ ] Product ID 與程式碼一致（com.kelvintan.NotchDrop.pro）
- [ ] 價格設定為 Tier 5（$4.99）
- [ ] IAP 的 EN + ZH-TW 描述已填寫

### Build
- [ ] Build 已透過 Xcode 上傳到 TestFlight
- [ ] Build 已選擇提交審核

### Review Information
- [ ] Review Notes 已填寫（上方文字）
- [ ] Contact email 已填寫

### Privacy
- [ ] App Privacy 選「不收集資料」
