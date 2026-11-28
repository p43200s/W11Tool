$ErrorActionPreference = "Stop"
$RootDir = if ($env:WIN_TOOL_ROOT) { $env:WIN_TOOL_ROOT } else { Split-Path -Parent $PSScriptRoot }

if (-not (Get-Module -Name "WinToolUtils")) {
    Import-Module (Join-Path $PSScriptRoot "utils.psm1") -Force
}
if (-not (Get-Module -Name "WinToolUI")) {
    Import-Module (Join-Path $PSScriptRoot "ui.psm1") -Force
}

Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" | Where-Object { $_.Name -ne "menu.ps1" } | ForEach-Object {
    . $_.FullName
}

Invoke-SelfUpdateCheck -RootDir $RootDir -SilentIfLatest

while ($true) {
    $cfg = Get-WinToolConfig -RootDir $RootDir
    $ver = Get-AppVersion -RootDir $RootDir
    $Host.UI.RawUI.WindowTitle = "$($cfg.AppName) v$ver"

    $rtEnabled = Get-DefenderRealtimeState
    $rtState   = if ($rtEnabled) { "開" } else { "關" }
    $rtColor   = if ($rtEnabled) { "Green" } else { "Yellow" }

    $netOk    = Test-InternetConnection -Silent
    $netLabel = if ($netOk) { "已連線" } else { "離線" }
    $netColor = if ($netOk) { "Green" } else { "Red" }

    $sysSummary = Get-SystemSummary
    $div        = Get-LineDivider

    Show-Header -RootDir $RootDir
    Write-Host " $($sysSummary.Line1)" -ForegroundColor Gray
    Write-Host " $($sysSummary.Line2)" -ForegroundColor Gray
    Write-Host -NoNewline " 網路: " -ForegroundColor Gray
    Write-Host -NoNewline $netLabel -ForegroundColor $netColor
    Write-Host -NoNewline " │ Windows 安全性即時保護：" -ForegroundColor Gray
    Write-Host -NoNewline $rtState -ForegroundColor $rtColor
    Write-Host "（按 R 切換）" -ForegroundColor Gray
    Write-Host $div -ForegroundColor DarkCyan

    Write-Host " [ 1] 線上工具庫"
    Write-Host " [ 2] 系統調校與註冊表"
    Write-Host " [ 3] Office 部署與 KMS 啟動"
    Write-Host " [ 4] 常用工具安裝"
    Write-Host " [ 5] GitHub 專案管理中心"
    Write-Host " [ 6] 系統硬體資訊"
    Write-Host ""
    Write-Host " [99] 軟體更新"
    Show-Footer -HintText " [ 0] 離開"

    $choice = (Read-Host "請輸入選項").Trim()

    if ($choice -eq "0") { exit }

    if ($choice -ieq "R") {
        Switch-DefenderRealtimeProtection
        Wait-UserPause -Message "<< 按 Enter 繼續 >>"
        continue
    }

    if ($choice -ieq "B") {
        $buildScript = if ($PSScriptRoot) { Join-Path $PSScriptRoot "dev\build.ps1" } else { "" }
        if ($buildScript -and (Test-Path $buildScript)) {
            & $buildScript -RootDir $RootDir
        } else {
            Write-Status -Level "WARN" -Message "目前已是單一封裝執行檔。"
        }
        Wait-UserPause -Message "<< 按 Enter 繼續 >>"
        continue
    }

    if ($choice -ieq "O") {
        $dumpScript = if ($PSScriptRoot) { Join-Path $PSScriptRoot "dev\code_dump.ps1" } else { "" }
        if ($dumpScript -and (Test-Path $dumpScript)) {
            & $dumpScript -RootDir $RootDir
        } else {
            Write-Status -Level "WARN" -Message "單一封裝模式下不支援匯出原始碼。"
        }
        Wait-UserPause -Message "<< 按 Enter 繼續 >>"
        continue
    }

    try {
        switch ($choice) {
            "1"  { Show-OnlineToolsMenu -RootDir $RootDir }
            "2"  { Show-TweaksMenu }
            "3"  { Show-OfficeMenu -RootDir $RootDir }
            "4"  { Show-SoftwareInstallMenu -RootDir $RootDir }
            "5"  { Show-GitHubDownloadMenu -RootDir $RootDir }
            "6"  { Start-Process msinfo32 }
            "99" { Invoke-SystemSoftwareUpdate }
        }
    } catch {
        Write-Host ""
        Write-Status -Level "ERR" -Message $_.Exception.Message
        Wait-UserPause -Message "<< 按 Enter 繼續 >>"
    }
}