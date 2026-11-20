# W11Tool — Windows 11 模組化裝機與系統調校工具箱

**W11Tool** 是一套專為 Windows 11 設計的模組化裝機與系統維護工具箱。採用「設定檔驅動 (`config.psd1`) + 模組化 PowerShell」架構，整合了常用軟體批次安裝、系統登錄檔調校、Office 客製化部署、GitHub 免安裝專案管理以及系統硬體即時監控，並支援打包為單一 `.bat` 執行檔隨身攜帶。

> ⚠️ **免責聲明**：本工具箱包含系統登錄檔修改、Defender 即時保護切換、第三方線上調校腳本呼叫與 KMS 啟動等功能，請在了解各項功能用途的前提下使用，建議於全新系統部署或測試環境中操作。

---

## ✨ 核心功能亮點

* **📊 即時硬體與安全狀態儀表板**
  啟動時自動偵測並顯示 CPU、主機板廠牌型號、記憶體容量、Windows 11 版本建置號、網路連線狀態，以及 Windows 安全性「即時保護」開關狀態（支援一鍵快速切換與竄改防護狀態偵測）。
* **📦 WinGet 常用與內建軟體批次安裝**
  * 自動掃描本機已安裝狀態，在雙欄選單中標註 `[已裝]` 並自動跳過重複安裝。
  * 支援範圍多選（如 `1,3,5-8`）、全選未安裝項目 (`[A]`)，以及一鍵套用預設定義的裝機快捷包（基礎裝機包 `P1`、硬體檢測包 `P2`、Win11 內建工具補齊包 `P3`）。
  * 內建 WinGet 環境異常自動修復（重新註冊 App Installer 與重置來源）。
* **🐙 GitHub Releases 免安裝專案管理中心**
  * 直接透過 GitHub API 追蹤並下載指定的免安裝工具（預設整合 `ConvertZZ`、`Locale-Emulator`、`Rufus`、`WindowTranslator`）。
  * 自動部署至 `C:\Tools\<專案名稱>` 並記錄本地版本狀態 (`installed.json`)，支援 30 分鐘 API 快取防限流、版本比對更新與一鍵完整移除。
* **🛠️ 系統調校與註冊表管理**
  * 滑鼠右鍵選單一鍵切換「傳統右鍵風格（支援 Win11 26H2）」或還原新版風格，自動重啟 Explorer 生效。
  * 一鍵複製並啟用隱藏的「終極效能 (Ultimate Performance)」電源計畫。
  * 徹底移除 Xbox Game Bar 並修復 `ms-gamebar` 系統協定關聯彈窗錯誤。
* **📄 Office 自動化部署與元件精簡**
  * 自動從微軟官網取得最新版 Office Deployment Tool (ODT)，支援一鍵部署 Office 2024 Standard、Office 365 Home / Business。
  * 支援針對已安裝的 Office 進行元件精簡（移除 OneDrive、Teams、Outlook 等非必要元件）與自動 KMS 測試連線。
* **🌐 線上工具庫整合**
  * 集中管理並即時拉取執行知名的開源 Windows 維護腳本（如 MAS、Win11Debloat、Chris Titus Tech's Windows Utility）。
* **⚡ Polyglot 單一執行檔打包**
  * 內建建置腳本可自動解除檔案封鎖 (`Zone.Identifier`)、自動請求系統管理員權限 (`UAC`)，並將所有模組與設定檔封裝為單一 `.bat` 執行檔。

---

## 🚀 快速開始

### 方式一：下載單一封裝檔（推薦一般使用者）
1. 前往本專案的 [Releases](../../releases) 頁面，下載最新版的 `W11Tool_x.x.x.bat`。
2. 雙擊執行該檔案（程式會自動解除網路下載封鎖並請求系統管理員權限）。

### 方式二：使用原始碼執行（推薦開發者）
1. Clone 本儲存庫：
   ```bash
   git clone https://github.com/你的帳號/W11Tool.git
   cd W11Tool
   ```
2. 雙擊執行根目錄下的 `start.bat` 即可自動提權並開啟主選單。

---

## 📁 目錄結構說明

```text
W11Tool/
├── _modules/
│   ├── dev/
│   │   ├── build.ps1         # 打包腳本：動態組裝所有模組為 Polyglot 單一 .bat 執行檔
│   │   └── code_dump.ps1     # 開發輔助：匯出目錄樹與完整原始碼快照
│   ├── config.psd1           # 中央設定檔（軟體清單、快捷包、GitHub 專案、線上工具、KMS 清單）
│   ├── github.ps1            # GitHub Releases 專案下載、解壓部署與版本追蹤模組
│   ├── menu.ps1              # 主程式進入點與系統狀態儀表板
│   ├── office.ps1            # ODT 自動下載、XML 生成與 Office 部署/精簡模組
│   ├── online.ps1            # 線上 PowerShell 工具即時載入執行模組
│   ├── software.ps1          # WinGet 軟體雙欄選單安裝與全機更新模組
│   ├── system.ps1            # 系統登錄檔調校、電源計畫、Game Bar 移除與 Defender 控制
│   ├── ui.psm1               # 終端機 TUI 繪製引擎（CJK 寬度對齊、雙欄網格、資料驅動選單迴圈）
│   └── utils.psm1            # 核心工具函式（硬體資訊快取、網路檢測、WinGet 修復、多選解析）
└── start.bat                 # 開發模式啟動入口（自動 UTF-8 編碼與 UAC 提權）
```

---

## ⚙️ 自訂擴充教學

所有清單皆集中於 `_modules/config.psd1`，無需修改主程式邏輯即可自由擴充：

### 1. 新增 WinGet 常用軟體或快捷包
在 `SoftwareList` 中加入套件資訊（支援 `winget` 與 `msstore` 來源）：
```powershell
@{ Cat = "開發"; Name = "Git"; Id = "Git.Git"; Src = "winget" }
```

### 2. 新增 GitHub Releases 追蹤專案
在 `GitHubList` 中填入倉庫路徑與檔案匹配規則（支援萬用字元）：
```powershell
@{
    Name    = "7-Zip ZS"
    Repo    = "mcmilk/7-Zip-zstd"
    Tag     = ""                  # 留空代表自動抓取 Latest Release
    Pattern = "*x64.exe"
    Desc    = "支援 Zstandard 演算法的 7-Zip 分支版"
}
```
> 💡 **提示**：若頻繁查詢 GitHub API 遇到速率限制 (Rate Limit)，可在系統環境變數中設定 `GITHUB_TOKEN` 以提高請求上限。

---

## 👨‍💻 開發者隱藏指令

在 **主選單** 畫面中（僅限原始碼開發模式），支援以下隱藏快捷鍵：
* **`[B]`**：執行 `_modules/dev/build.ps1`，將目前所有模組與設定檔打包為獨立的 `W11Tool_<版本號>.bat`。
* **`[O]`**：執行 `_modules/dev/code_dump.ps1`，匯出目錄樹與程式碼快照至 `code_dump.txt`。

---

## 📋 系統需求

* **作業系統**：Windows 11（亦相容於多數 Windows 10 環境）
* **執行環境**：內建 Windows PowerShell 5.1+、`curl.exe` 與 `winget`（應用程式安裝程式）
* **權限需求**：需以**系統管理員身分**執行（啟動器會自動觸發 UAC 提權）

---

## 📄 授權條款

本專案採用 [MIT License](LICENSE) 授權。