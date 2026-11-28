$global:WinToolWidth = 100

function Get-LineDivider {
    param([string]$Char = "─")
    return ($Char * $global:WinToolWidth)
}

function Get-VisualWidth {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return 0 }
    $visWidth = 0
    foreach ($char in $Text.ToCharArray()) {
        $code = [int]$char
        # 常見 Box Drawing (0x2500-0x257F) 與單寬標點 (如 › 0x203A) 視為 1 格；CJK 與全形符號視為 2 格
        if (($code -ge 0x1100 -and $code -le 0xFFEF) -or ($code -ge 0x2E80 -and $code -le 0x9FFF)) {
            $visWidth += 2
        } else {
            $visWidth += 1
        }
    }
    return $visWidth
}

function Format-PadRight {
    param([string]$Text, [int]$Width)
    $visWidth = Get-VisualWidth -Text $Text
    $pad = [Math]::Max(0, $Width - $visWidth)
    return $Text + (" " * $pad)
}

function Write-Status {
    param(
        [ValidateSet("INFO", "OK", "WARN", "ERR", "STEP")]
        [string]$Level = "INFO",
        [string]$Message
    )
    $colorMap = @{
        "INFO" = "Cyan"
        "OK"   = "Green"
        "WARN" = "Yellow"
        "ERR"  = "Red"
        "STEP" = "Magenta"
    }
    Write-Host "[$Level] " -NoNewline -ForegroundColor $colorMap[$Level]
    Write-Host $Message
}

function Show-Header {
    param(
        [string]$Subtitle = "",
        [string]$RootDir = $env:WIN_TOOL_ROOT
    )
    Clear-Host
    $cfg = Get-WinToolConfig -RootDir $RootDir
    $ver = Get-AppVersion -RootDir $RootDir
    $div = Get-LineDivider

    Write-Host $div -ForegroundColor DarkCyan
    $baseTitle = " $($cfg.AppName) v$ver"
    $title = if ($Subtitle) { "$baseTitle  ›  $Subtitle" } else { $baseTitle }
    Write-Host $title -ForegroundColor Cyan
    Write-Host $div -ForegroundColor DarkCyan
}

function Show-Footer {
    param([string]$HintText = " [ 0] 返回主選單")
    $div = Get-LineDivider
    if ($HintText) {
        Write-Host $div -ForegroundColor DarkCyan
        Write-Host $HintText
    }
    Write-Host $div -ForegroundColor DarkCyan
}

function Show-TwoColumnGrid {
    param(
        [array]$Items,
        [scriptblock]$FormatLabel,
        [scriptblock]$GetTag = $null
    )
    $colWidth = [Math]::Floor(($global:WinToolWidth - 3) / 2)
    $half     = [Math]::Ceiling($Items.Count / 2)

    for ($i = 0; $i -lt $half; $i++) {
        $leftIdx  = $i + 1
        $leftText = & $FormatLabel $Items[$i] $leftIdx
        $leftTag  = if ($GetTag) { & $GetTag $Items[$i] } else { "" }
        $leftBase = " [{0,2}] {1}" -f $leftIdx, $leftText

        if ($leftTag) {
            $tagSpace = [Math]::Max(1, $colWidth - (Get-VisualWidth $leftBase) - (Get-VisualWidth $leftTag))
            Write-Host -NoNewline $leftBase
            Write-Host -NoNewline (" " * $tagSpace)
            Write-Host -NoNewline $leftTag -ForegroundColor Green
        } else {
            Write-Host -NoNewline (Format-PadRight $leftBase $colWidth)
        }

        $rightIdx = $i + $half + 1
        if ($rightIdx -le $Items.Count) {
            Write-Host -NoNewline " │ " -ForegroundColor DarkGray
            $rightText = & $FormatLabel $Items[$rightIdx - 1] $rightIdx
            $rightTag  = if ($GetTag) { & $GetTag $Items[$rightIdx - 1] } else { "" }
            $rightBase = " [{0,2}] {1}" -f $rightIdx, $rightText

            if ($rightTag) {
                $rTagSpace = [Math]::Max(1, $colWidth - (Get-VisualWidth $rightBase) - (Get-VisualWidth $rightTag))
                Write-Host -NoNewline $rightBase
                Write-Host -NoNewline (" " * $rTagSpace)
                Write-Host $rightTag -ForegroundColor Green
            } else {
                Write-Host $rightBase
            }
        } else {
            Write-Host ""
        }
    }
}

# 通用資料驅動選單引擎
function Invoke-MenuLoop {
    param(
        [string]$Subtitle,
        [array]$MenuItems,
        [string]$Prompt = "請輸入選項"
    )
    while ($true) {
        Show-Header -Subtitle $Subtitle
        foreach ($item in $MenuItems) {
            if ($item.Separator) {
                Write-Host ""
                continue
            }
            Write-Host (" [{0,2}] {1}" -f $item.Key, $item.Label)
        }
        Show-Footer
        $opt = (Read-Host $Prompt).Trim()
        if ($opt -eq "0") { return }

        $matched = $MenuItems | Where-Object { -not $_.Separator -and $_.Key -eq $opt } | Select-Object -First 1
        if ($matched -and $matched.Action) {
            try {
                & $matched.Action
                if (-not $matched.NoPause) {
                    Wait-UserPause
                }
            } catch {
                Write-Status -Level "ERR" -Message $_.Exception.Message
                Wait-UserPause
            }
        }
    }
}

# 通用分頁選單引擎 (支援 ←/→ 與 PageUp/PageDown 翻頁，並保留直接輸入指令)
# 通用分頁選單引擎 (全程接管按鍵輸入：支援隨時 ←/→/PgUp/PgDn 翻頁並保留已輸入文字、Backspace 刪除)
function Invoke-PagedMenu {
    param(
        [string]$Subtitle,
        [array]$Items,
        [int]$PageSize = 6,
        [switch]$Compact,
        [scriptblock]$RenderHeaderExtra = $null,
        [scriptblock]$RenderItem,
        [scriptblock]$RenderFooterCommands = $null,
        [scriptblock]$OnCommand
    )

    $page    = 0
    $inputSb = New-Object System.Text.StringBuilder

    while ($true) {
        $totalPages = [Math]::Max(1, [Math]::Ceiling($Items.Count / $PageSize))
        if ($page -ge $totalPages) { $page = $totalPages - 1 }
        if ($page -lt 0) { $page = 0 }

        $pageHint = if ($totalPages -gt 1) { "$Subtitle  [第 $($page + 1) / $totalPages 頁]" } else { $Subtitle }
        Show-Header -Subtitle $pageHint

        if ($RenderHeaderExtra) {
            & $RenderHeaderExtra
        }

        $startIdx = $page * $PageSize
        $endIdx   = [Math]::Min($startIdx + $PageSize - 1, $Items.Count - 1)

        for ($i = $startIdx; $i -le $endIdx; $i++) {
            & $RenderItem $Items[$i] $i
            if (-not $Compact -and $i -lt $endIdx) {
                Write-Host ""
            }
        }

        if ($RenderFooterCommands) {
            & $RenderFooterCommands
        }

        $navHint = if ($totalPages -gt 1) {
            " [ 0] 返回主選單    │    [← / PgUp] 上一頁    [→ / PgDn] 下一頁"
        } else {
            " [ 0] 返回主選單"
        }
        Show-Footer -HintText $navHint

        # 印出提示詞與目前已輸入的緩衝區內容（翻頁後會自動保留已打的字）
        Write-Host -NoNewline ("請輸入指令: " + $inputSb.ToString())

        # 內層逐鍵讀取迴圈
        while ($true) {
            $keyInfo = [Console]::ReadKey($true)

            # 1. 隨時攔截翻頁鍵（即使已經輸入一半的數字也能直接翻頁，且不產生亂碼）
            if ($keyInfo.Key -eq [ConsoleKey]::PageDown -or $keyInfo.Key -eq [ConsoleKey]::RightArrow) {
                if ($totalPages -gt 1) {
                    $page = ($page + 1) % $totalPages
                    break
                }
                continue
            }
            if ($keyInfo.Key -eq [ConsoleKey]::PageUp -or $keyInfo.Key -eq [ConsoleKey]::LeftArrow) {
                if ($totalPages -gt 1) {
                    $page = ($page - 1 + $totalPages) % $totalPages
                    break
                }
                continue
            }

            # 2. 忽略上下方向鍵與功能鍵，防止終端機印出異常控制字元
            if ($keyInfo.Key -eq [ConsoleKey]::UpArrow -or $keyInfo.Key -eq [ConsoleKey]::DownArrow) {
                continue
            }

            # 3. Esc：若有輸入文字則先清空輸入框；若輸入框已空則直接返回主選單
            if ($keyInfo.Key -eq [ConsoleKey]::Escape) {
                if ($inputSb.Length -gt 0) {
                    $clearWidth = Get-VisualWidth -Text $inputSb.ToString()
                    Write-Host -NoNewline (("`b" * $clearWidth) + (" " * $clearWidth) + ("`b" * $clearWidth))
                    [void]$inputSb.Clear()
                    continue
                } else {
                    return
                }
            }

            # 4. Backspace：精準刪除最後一個字元（相容全形/中文雙倍寬度退格）
            if ($keyInfo.Key -eq [ConsoleKey]::Backspace) {
                if ($inputSb.Length -gt 0) {
                    $lastChar  = $inputSb[$inputSb.Length - 1].ToString()
                    $charWidth = Get-VisualWidth -Text $lastChar
                    [void]$inputSb.Remove($inputSb.Length - 1, 1)
                    Write-Host -NoNewline (("`b" * $charWidth) + (" " * $charWidth) + ("`b" * $charWidth))
                }
                continue
            }

            # 5. Enter：送出目前緩衝區的完整指令
            if ($keyInfo.Key -eq [ConsoleKey]::Enter) {
                Write-Host ""
                $raw = $inputSb.ToString().Trim()
                [void]$inputSb.Clear()

                if ($raw -eq "0") { return }
                if ([string]::IsNullOrWhiteSpace($raw)) { break }

                $actionResult = & $OnCommand $raw
                if ($actionResult -eq "EXIT") { return }
                break
            }

            # 6. 一般可列印字元（數字、英文、逗號、空白等）：加入緩衝區並顯示在畫面上
            if (-not [char]::IsControl($keyInfo.KeyChar)) {
                [void]$inputSb.Append($keyInfo.KeyChar)
                Write-Host -NoNewline $keyInfo.KeyChar
            }
        }
    }
}

function Wait-UserPause {
    param([string]$Message = "<< 按 Enter 繼續 >>")
    Write-Host ""
    Write-Host $Message -ForegroundColor Yellow
    while ($true) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Enter) { break }
    }
}

Export-ModuleMember -Function Get-LineDivider, Get-VisualWidth, Format-PadRight, Write-Status, Show-Header, Show-Footer, Show-TwoColumnGrid, Invoke-MenuLoop, Invoke-PagedMenu, Wait-UserPause