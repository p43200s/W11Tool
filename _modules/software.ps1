function Show-SoftwareInstallMenu {
    param([string]$RootDir)
    if (-not (Test-InternetConnection)) { return }
    if (-not (Confirm-WinGetReady)) { return }

    $cfg  = Get-WinToolConfig -RootDir $RootDir
    $list = @($cfg.SoftwareList)

    if ($list.Count -eq 0) {
        Write-Status -Level "WARN" -Message "config.psd1 中尚未設定任何 SoftwareList 項目。"
        Wait-UserPause -Message "<< 按 Enter 繼續 >>"
        return
    }

    Write-Status -Level "INFO" -Message "正在比對本機已安裝軟體狀態..."
    $installedSet = Get-InstalledWinGetIds

    $invokeInstallIndices = {
        param([int[]]$Indices)
        $validIndices = [System.Collections.Generic.List[int]]::new()
        foreach ($n in @($Indices)) {
            if ($n -ge 1 -and $n -le $list.Count -and -not $validIndices.Contains($n)) {
                [void]$validIndices.Add($n)
            }
        }
        if ($validIndices.Count -eq 0) { return }

        $total = $validIndices.Count
        $step  = 0
        foreach ($idx in $validIndices) {
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

    $pageSize = 40
    $pageRows = @()
    for ($start = 0; $start -lt $list.Count; $start += $pageSize) {
        $end = [Math]::Min($start + $pageSize - 1, $list.Count - 1)
        $pageRows += ,@($start..$end)
    }

    $div      = Get-LineDivider
    $colWidth = [Math]::Floor(($global:WinToolWidth - 3) / 2)

    Invoke-PagedMenu -Subtitle "常用與內建軟體安裝" -Items $pageRows -PageSize 1 -Compact `
        -RenderItem {
            param($sliceIndices, $pageIdx)
            $slice = @($sliceIndices | ForEach-Object {
                [PSCustomObject]@{
                    GlobalIdx = $_
                    Item      = $list[$_]
                }
            })
            $half = [Math]::Ceiling($slice.Count / 2)

            for ($r = 0; $r -lt $half; $r++) {
                $leftEntry = $slice[$r]
                $leftNum   = $leftEntry.GlobalIdx + 1
                $leftBase  = " [{0,2}] [{1}] {2}" -f $leftNum, $leftEntry.Item.Cat, $leftEntry.Item.Name
                $leftDone  = $installedSet.Contains($leftEntry.Item.Id)
                $leftTag   = if ($leftDone) { "[已裝]" } else { "" }

                if ($leftDone) {
                    $lSpace = [Math]::Max(1, $colWidth - (Get-VisualWidth $leftBase) - (Get-VisualWidth $leftTag))
                    Write-Host -NoNewline $leftBase
                    Write-Host -NoNewline (" " * $lSpace)
                    Write-Host -NoNewline $leftTag -ForegroundColor Green
                } else {
                    Write-Host -NoNewline (Format-PadRight $leftBase $colWidth)
                }

                $rightPos = $r + $half
                if ($rightPos -lt $slice.Count) {
                    Write-Host -NoNewline " │ " -ForegroundColor DarkGray
                    $rightEntry = $slice[$rightPos]
                    $rightNum   = $rightEntry.GlobalIdx + 1
                    $rightBase  = " [{0,2}] [{1}] {2}" -f $rightNum, $rightEntry.Item.Cat, $rightEntry.Item.Name
                    $rightDone  = $installedSet.Contains($rightEntry.Item.Id)
                    $rightTag   = if ($rightDone) { "[已裝]" } else { "" }

                    if ($rightDone) {
                        $rSpace = [Math]::Max(1, $colWidth - (Get-VisualWidth $rightBase) - (Get-VisualWidth $rightTag))
                        Write-Host -NoNewline $rightBase
                        Write-Host -NoNewline (" " * $rSpace)
                        Write-Host $rightTag -ForegroundColor Green
                    } else {
                        Write-Host $rightBase
                    }
                } else {
                    Write-Host ""
                }
            }
        } `
        -RenderFooterCommands {
            Write-Host $div -ForegroundColor DarkCyan
            Write-Host " [數字] 多選安裝 (如: 1,3,5-8)  │  [F] 重新掃描狀態  │  [N] NVCleanstall 說明對照表"
        } `
        -OnCommand {
            param($raw)
            if ($raw -ieq "N") {
                Show-NVCleanstallGuide
                return
            }

            if ($raw -ieq "F") {
                Write-Host ""
                Write-Status -Level "INFO" -Message "正在重新掃描本機已安裝軟體狀態..."
                $installedSet = Get-InstalledWinGetIds -ForceRefresh
                return
            }

            $parsed = @(Resolve-MultiSelection -InputStr $raw -MaxCount $list.Count)
            if ($parsed.Count -gt 0) {
                & $invokeInstallIndices -Indices $parsed
            }
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