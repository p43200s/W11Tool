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

function Wait-UserPause {
    param([string]$Message = "<< 按 Enter 繼續 >>")
    Write-Host ""
    Write-Host $Message -ForegroundColor Yellow
    while ($true) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Enter) { break }
    }
}

Export-ModuleMember -Function Get-LineDivider, Get-VisualWidth, Format-PadRight, Write-Status, Show-Header, Show-Footer, Show-TwoColumnGrid, Invoke-MenuLoop, Wait-UserPause