function Invoke-SelfUpdateCheck {
    param(
        [string]$RootDir = $env:WIN_TOOL_ROOT,
        [switch]$SilentIfLatest
    )

    if (-not (Test-InternetConnection -Silent)) {
        Start-Sleep -Seconds 1
        if (-not (Test-InternetConnection -Silent)) {
            return
        }
    }

    $currentVer = ((Get-AppVersion -RootDir $RootDir) -replace '^[vV]\s*', '').Trim()
    $repo = "p43200s/W11Tool"
    $apiUrl = "https://api.github.com/repos/$repo/releases/latest"

    $headers = @{
        "User-Agent" = "W11Tool-Updater"
        "Accept"     = "application/vnd.github+json"
    }

    try {
        $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 12 -ErrorAction Stop
    } catch {
        if (-not $SilentIfLatest) {
            Write-Status -Level "WARN" -Message "無法檢查 GitHub 更新：$($_.Exception.Message)"
            Wait-UserPause -Message "<< 按 Enter 進入主選單 >>"
        }
        return
    }

    $latestTag = (($release.tag_name) -replace '^[vV]\s*', '').Trim()
    if ([string]::IsNullOrWhiteSpace($latestTag) -or [string]::IsNullOrWhiteSpace($currentVer)) {
        return
    }

    $isNewer = $false
    try {
        $curBase = ($currentVer -split '-')[0]
        $latBase = ($latestTag -split '-')[0]
        $isNewer = ([version]$latBase -gt [version]$curBase)
    } catch {
        $isNewer = ($latestTag -ne $currentVer)
    }

    if (-not $isNewer) {
        if (-not $SilentIfLatest) {
            Write-Status -Level "OK" -Message "目前已是最新版本 (v$currentVer)。"
            Wait-UserPause -Message "<< 按 Enter 進入主選單 >>"
        }
        return
    }

    Write-Host ""
    Write-Status -Level "INFO" -Message "發現新版本！目前版本：v$currentVer  →  最新版本：v$latestTag"
    if ($release.name) {
        Write-Host "       更新說明：$($release.name)" -ForegroundColor Gray
    }

    $ans = (Read-Host "是否立即下載最新版本？(Y/n)").Trim()
    if ($ans -ne "" -and $ans -ine "Y") {
        Write-Status -Level "WARN" -Message "已略過此次更新。"
        Wait-UserPause -Message "<< 按 Enter 進入主選單 >>"
        return
    }

    $isPackedBat = (-not [string]::IsNullOrWhiteSpace($env:WIN_TOOL_FILE)) -and (Test-Path $env:WIN_TOOL_FILE)
    $asset = $null

    if ($isPackedBat) {
        $asset = @($release.assets) | Where-Object { $_.name -like "W11Tool_*.bat" } | Select-Object -First 1
    }

    if (-not $asset) {
        $asset = @($release.assets) | Select-Object -First 1
    }

    if (-not $asset) {
        Write-Status -Level "WARN" -Message "此 Release 沒有可直接下載的附件，將開啟 GitHub Releases 頁面。"
        Start-Process "https://github.com/$repo/releases/latest"
        Wait-UserPause -Message "<< 按 Enter 進入主選單 >>"
        return
    }

    $targetDir = if ($isPackedBat) { Split-Path -Parent $env:WIN_TOOL_FILE } else { $RootDir }
    $outPath = Join-Path $targetDir $asset.name

    Write-Status -Level "STEP" -Message "正在下載 $($asset.name)..."
    & curl.exe -L -# "$($asset.browser_download_url)" -o "$outPath"

    if ($LASTEXITCODE -eq 0 -and (Test-Path $outPath)) {
        Write-Host ""
        Write-Status -Level "OK" -Message "新版已下載至：$outPath"
        Write-Host "       下載資料夾：$targetDir" -ForegroundColor Cyan
        Write-Host "       請關閉目前這個舊版視窗，改執行上方路徑的新版檔案即可。" -ForegroundColor Yellow
        Wait-UserPause -Message "<< 按 Enter 關閉目前視窗 >>"
        exit
    } else {
        Write-Status -Level "ERR" -Message "下載失敗，請稍後再試或手動至 GitHub 下載。"
        Wait-UserPause -Message "<< 按 Enter 進入主選單 >>"
    }
}