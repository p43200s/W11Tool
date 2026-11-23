# 更新日誌

## [0.3.1] - 2026-11-23

### 新增

- **NVCleanstall 中文對照速查表 (`_modules/guides.ps1`)**：於「常用工具安裝」選單加入 `[N]` 快捷鍵，點擊可彈出獨立深色 WPF 圖形化視窗，完整收錄元件選擇、安裝微調與進階專家微調的繁體中文說明與勾選建議。
- **長清單互動式分頁引擎 (`_modules/ui.psm1`)**：新增 `Invoke-PagedMenu` 通用分頁元件並套用至「線上工具庫」與「GitHub 專案管理中心」，支援鍵盤方向鍵（`←` / `→`）與 `PageUp` / `PageDown` 翻頁，並可保留輸入到一半的指令進行跨頁多選操作。
- **擴充預設工具清單 (`_modules/config.psd1`)**：
  - 於 `GitHubList` 新增 `balenaEtcher`、`Ventoy`、`LunaTranslator`、`Magpie` 等免安裝版本追蹤規則。
  - 於 `OnlineTools` 補回 `RemoveWindowsAI`（深度清除 Windows 11 內建 AI 功能）腳本。

### 調整

- **多選操作提示優化 (`software.ps1` / `github.ps1`)**：更新介面指令提示文字，明確標示批次輸入編號時支援逗號或空白鍵分隔（如 `1,3,5` 或 `1 3 5`）。
- **選單排版視覺間距 (`_modules/ui.psm1`)**：在分頁選單的同頁項目之間固定加入空行留白，提升長清單閱讀清晰度。
- **打包腳本版本讀取簡化 (`_modules/dev/build.ps1`)**：移除資料夾名稱後綴正則推斷邏輯，改由 `Import-PowerShellDataFile` 直接讀取 `config.psd1` 的 `DefaultVer` 作為預設打包版本號。
- **原始碼快照過濾強化 (`_modules/dev/code_dump.ps1`)**：加入檔名正規表達式與 Polyglot 檔頭特徵（`<# :`）雙重檢查，確保匯出 `code_dump.txt` 時自動排除所有打包產出的單一執行檔。
- **說明文件更新 (`README.md`)**：同步補齊 `guides.ps1` 目錄結構、新功能亮點與 AI 輔助開發聲明。

### 修復

- **Polyglot 單一執行檔無法啟動 (`_modules/dev/build.ps1`)**：
  - 將輸出檔案編碼由 `UTF-8 with BOM` 改為 `UTF-8 without BOM`，解決 `cmd.exe` 誤判檔頭 BOM 位元組導致首行 `<# :` 報錯閃退的問題。
  - 修正清理 `menu.ps1` 動態載入區塊的正規表示式，避免打包後的單檔殘留 `| ForEach-Object` 語法導致執行異常。
- **分頁輸入時按翻頁鍵產生亂碼 (`_modules/ui.psm1`)**：改用 `[Console]::ReadKey($true)` 全程接管按鍵輸入緩衝區取代 `Read-Host`，修復輸入編號中途按方向鍵或 `PageUp`/`PageDown` 時終端機印出逸出序列字元且無法退格刪除的問題。