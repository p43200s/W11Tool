function Show-SoftwareInstallMenu {
    param([string]$RootDir)
    if (-not (Test-InternetConnection)) { return }
    if (-not (Confirm-WinGetReady)) { return }

    $cfg     = Get-WinToolConfig -RootDir $RootDir
    $list    = $cfg.SoftwareList
    $presets = $cfg.SoftwarePresets

    Write-Status -Level "INFO" -Message "正在比對本機已安裝軟體狀態..."
    $installedSet = Get-InstalledWinGetIds

    while ($true) {
        $div = Get-LineDivider
        Show-Header -Subtitle "常用與內建軟體安裝"

        Show-TwoColumnGrid -Items $list `
            -FormatLabel { param($item) "[$($item.Cat)] $($item.Name)" } `
            -GetTag { param($item) if ($installedSet.Contains($item.Id)) { "[已裝]" } else { "" } }

        Write-Host $div -ForegroundColor DarkCyan
        if ($presets -and $presets.Count -gt 0) {
            foreach ($p in $presets) {
                Write-Host (" [{0}] {1}" -f $p.Key, $p.Name) -ForegroundColor Cyan
            }
            Write-Host $div -ForegroundColor DarkCyan
        }

        $cmdLeft1  = Format-PadRight " [數字] 多選安裝 (如: 1,3,5-8)" 42
        $cmdRight1 = "[組合] 套用快捷包 (如: P1)"
        Write-Host "$cmdLeft1$cmdRight1"

        $cmdLeft2  = Format-PadRight " [A] 全選未安裝項目" 42
        $cmdRight2 = "[F] 重新掃描已安裝狀態"
        Write-Host "$cmdLeft2$cmdRight2"

        Show-Footer
        $raw = (Read-Host "請輸入指令").Trim()

        if ($raw -eq "0") { return }

        if ($raw -ieq "F") {
            Write-Status -Level "INFO" -Message "重新掃描本機已安裝清單..."
            $installedSet = Get-InstalledWinGetIds -ForceRefresh
            continue
        }

        $targetIndices = [System.Collections.Generic.List[int]]::new()

        if ($raw -ieq "A") {
            for ($i = 0; $i -lt $list.Count; $i++) {
                if (-not $installedSet.Contains($list[$i].Id)) {
                    $targetIndices.Add($i + 1)
                }
            }
            if ($targetIndices.Count -eq 0) {
                Write-Status -Level "OK" -Message "清單中所有軟體皆已安裝！"
                Wait-UserPause -Message "<< 按 Enter 返回主選單 >>"
                continue
            }
        } elseif ($presets -and ($presets.Key -contains $raw.ToUpper())) {
            $chosenPreset = $presets | Where-Object { $_.Key -ieq $raw } | Select-Object -First 1
            for ($i = 0; $i -lt $list.Count; $i++) {
                if ($chosenPreset.Ids -contains $list[$i].Id) {
                    $targetIndices.Add($i + 1)
                }
            }
        } else {
            $parsed = Resolve-MultiSelection -InputStr $raw -MaxCount $list.Count
            foreach ($n in $parsed) { $targetIndices.Add($n) }
        }

        if ($targetIndices.Count -eq 0) { continue }

        $total = $targetIndices.Count
        $step  = 0
        foreach ($idx in $targetIndices) {
            $step++
            $app = $list[$idx - 1]

            if ($installedSet.Contains($app.Id)) {
                Write-Host "`n[$step/$total] 跳過已安裝：$($app.Name)" -ForegroundColor DarkGray
                continue
            }

            Write-Host "`n[$step/$total] 正在安裝: $($app.Name) ($($app.Id))" -ForegroundColor Cyan
            winget install --id "$($app.Id)" --source "$($app.Src)" --silent --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -eq 0) {
                Write-Status -Level "OK" -Message "$($app.Name) 安裝成功。"
                [void]$installedSet.Add($app.Id)
            } else {
                Write-Status -Level "WARN" -Message "$($app.Name) 已是最新版本或安裝異常。"
            }
        }
        Wait-UserPause -Message "<< 批次作業完成，按 Enter 繼續 >>"
    }
}

function Invoke-SystemSoftwareUpdate {
    if (-not (Test-InternetConnection)) { return }
    if (-not (Confirm-WinGetReady)) { return }

    Show-Header -Subtitle "全機軟體更新 (WinGet)"
    Write-Status -Level "STEP" -Message "[1/2] 正在自動更新所有已知版本軟體..."
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements

    Write-Host ""
    Write-Status -Level "WARN" -Message "[2/2] 以下為版號未知 (Unknown) 或被跳過的軟體："
    winget upgrade --include-unknown
    Write-Host "`n[提示] 若需強制更新特定軟體，請執行: winget upgrade --id <套件ID> --include-unknown" -ForegroundColor DarkGray
    Wait-UserPause -Message "<< 按 Enter 返回主選單 >>"
}