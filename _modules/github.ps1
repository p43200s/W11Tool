function Get-GitHubStateFile {
    param([string]$DownloadDir)
    $statePath = Join-Path $DownloadDir "installed.json"
    if (Test-Path $statePath) {
        try {
            $raw = Get-Content $statePath -Raw -Encoding UTF8
            $obj = $raw | ConvertFrom-Json
            $ht  = @{}
            if ($obj) {
                foreach ($prop in $obj.PSObject.Properties) {
                    $ht[$prop.Name] = @{
                        Tag       = $prop.Value.Tag
                        FileName  = $prop.Value.FileName
                        Folder    = $prop.Value.Folder
                        LatestTag = $prop.Value.LatestTag
                        CheckedAt = $prop.Value.CheckedAt
                    }
                }
            }
            return $ht
        } catch {
            return @{}
        }
    }
    return @{}
}

function Save-GitHubStateFile {
    param(
        [string]$DownloadDir,
        [hashtable]$State
    )
    if (-not (Test-Path $DownloadDir)) {
        New-Item -Path $DownloadDir -ItemType Directory -Force | Out-Null
    }
    $statePath = Join-Path $DownloadDir "installed.json"
    $json = $State | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText($statePath, $json, (New-Object System.Text.UTF8Encoding $false))
}

function Get-GitHubReleaseInfo {
    param(
        [string]$Repo,
        [string]$Tag = ""
    )
    $headers = @{
        "User-Agent" = "W11Tool-PowerShell"
        "Accept"     = "application/vnd.github+json"
    }
    if ($env:GITHUB_TOKEN) {
        $headers["Authorization"] = "Bearer $($env:GITHUB_TOKEN)"
    }

    $apiUrl = if ([string]::IsNullOrWhiteSpace($Tag)) {
        "https://api.github.com/repos/$Repo/releases/latest"
    } else {
        "https://api.github.com/repos/$Repo/releases/tags/$Tag"
    }

    try {
        return Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 15 -ErrorAction Stop
    } catch {
        $statusCode = $null
        if ($_.Exception.PSObject.Properties.Match('Response').Count -gt 0 -and $_.Exception.Response) {
            try {
                $statusCode = [int]$_.Exception.Response.StatusCode
            } catch {
                try {
                    $statusCode = [int]$_.Exception.Response.StatusCode.value__
                } catch {}
            }
        }

        if ($statusCode -eq 403) {
            throw "GitHub API 請求次數已達上限 (Rate Limit)，請稍後再試。"
        } elseif ($statusCode -eq 404) {
            throw "找不到專案 ($Repo) 或指定的版本標籤 ($Tag)。"
        } else {
            throw "無法取得 GitHub Release 資訊：$($_.Exception.Message)"
        }
    }
}

function Invoke-GitHubAssetInstall {
    param(
        [hashtable]$Item,
        [string]$ToolsDir,
        [string]$DownloadDir,
        [hashtable]$State
    )
    $repoName   = ($Item.Repo -split '/')[-1]
    $extractDir = Join-Path $ToolsDir $repoName
    $curRecord  = if ($State[$Item.Repo]) { $State[$Item.Repo] } else { @{} }

    Write-Host "`n>>> 正在檢查: $($Item.Name) ($($Item.Repo)) <<<" -ForegroundColor Cyan
    $release   = Get-GitHubReleaseInfo -Repo $Item.Repo -Tag $Item.Tag
    $latestTag = $release.tag_name
    $assets    = @($release.assets)

    if ($assets.Count -eq 0) {
        Write-Status -Level "WARN" -Message "版本 $latestTag 中沒有任何可下載的附件檔案。"
        return
    }

    $pattern = if ($Item.Pattern) { $Item.Pattern } else { "*" }
    $matched = @($assets | Where-Object { $_.name -like $pattern })

    $targetAsset = $null
    if ($matched.Count -eq 1) {
        $targetAsset = $matched[0]
    } else {
        $candidateList = if ($matched.Count -gt 1) { $matched } else { $assets }
        Write-Status -Level "INFO" -Message "版本 $latestTag 找到多個檔案，請選擇要下載的項目："
        for ($i = 0; $i -lt $candidateList.Count; $i++) {
            $sizeMB = [Math]::Round($candidateList[$i].size / 1MB, 2)
            Write-Host ("  [{0}] {1} ({2} MB)" -f ($i + 1), $candidateList[$i].name, $sizeMB)
        }
        Write-Host "  [0] 跳過此專案"
        $pick = (Read-Host "請輸入編號").Trim()
        if ($pick -match '^\d+$' -and [int]$pick -ge 1 -and [int]$pick -le $candidateList.Count) {
            $targetAsset = $candidateList[[int]$pick - 1]
        } else {
            Write-Host "[跳過] 已取消 $($Item.Name)。" -ForegroundColor DarkGray
            return
        }
    }

    if (-not (Test-Path $DownloadDir)) {
        New-Item -Path $DownloadDir -ItemType Directory -Force | Out-Null
    }

    $outFile = Join-Path $DownloadDir $targetAsset.name
    $needDownload = $true

    if ((Test-Path $outFile) -and $curRecord.Tag -eq $latestTag -and $curRecord.FileName -eq $targetAsset.name) {
        Write-Status -Level "OK" -Message "_Download 已存在相同版本檔案 ($($targetAsset.name) / $latestTag)，跳過下載。"
        $needDownload = $false
    } elseif (Test-Path $outFile) {
        $reDl = (Read-Host "[提示] _Download 已存在同名檔案 $($targetAsset.name)，是否重新下載覆蓋？(y/N)").Trim()
        if ($reDl -ine "Y") { $needDownload = $false }
    }

    if ($needDownload) {
        if ($curRecord.FileName -and $curRecord.FileName -ne $targetAsset.name) {
            $oldZip = Join-Path $DownloadDir $curRecord.FileName
            if (Test-Path $oldZip) {
                Remove-Item $oldZip -Force -ErrorAction SilentlyContinue
                Write-Host "[清理] 已移除舊版壓縮檔: $($curRecord.FileName)" -ForegroundColor DarkGray
            }
        }

        $sizeMB = [Math]::Round($targetAsset.size / 1MB, 2)
        Write-Status -Level "STEP" -Message "版本: $latestTag | 檔案: $($targetAsset.name) ($sizeMB MB)"
        & curl.exe -L -# "$($targetAsset.browser_download_url)" -o "$outFile"
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $outFile)) {
            Write-Status -Level "ERR" -Message "$($targetAsset.name) 下載失敗。"
            return
        }
        Write-Status -Level "OK" -Message "檔案已儲存至: $outFile"
    }

    if ($targetAsset.name -match '\.zip$') {
        $doExtract = $true
        if (Test-Path $extractDir) {
            Write-Status -Level "WARN" -Message "目標資料夾已存在: $extractDir"
            $ov = (Read-Host "是否清空舊資料夾並以新版本覆蓋？(Y/n)").Trim()
            if ($ov -ne "" -and $ov -ine "Y") {
                $doExtract = $false
                Write-Host "[保留] 已取消覆蓋，保留原有資料夾內容。" -ForegroundColor DarkGray
            } else {
                Remove-Item -Path $extractDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        if ($doExtract) {
            $tmpDir = Join-Path $DownloadDir ("_tmp_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8))
            try {
                New-Item -Path $tmpDir -ItemType Directory -Force | Out-Null
                Expand-Archive -LiteralPath $outFile -DestinationPath $tmpDir -Force

                New-Item -Path $extractDir -ItemType Directory -Force | Out-Null
                $topItems = @(Get-ChildItem -Path $tmpDir -Force)

                if ($topItems.Count -eq 1 -and $topItems[0].PSIsContainer) {
                    Get-ChildItem -Path $topItems[0].FullName -Force | Move-Item -Destination $extractDir -Force
                } else {
                    Get-ChildItem -Path $tmpDir -Force | Move-Item -Destination $extractDir -Force
                }

                Write-Status -Level "OK" -Message "已部署至固定資料夾: $extractDir"
            } finally {
                if (Test-Path $tmpDir) {
                    Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    } elseif ($targetAsset.name -match '\.exe$') {
        if (-not (Test-Path $extractDir)) {
            New-Item -Path $extractDir -ItemType Directory -Force | Out-Null
        } else {
            if ($curRecord.FileName -and $curRecord.FileName -ne $targetAsset.name) {
                $oldExe = Join-Path $extractDir $curRecord.FileName
                if (Test-Path $oldExe) {
                    Remove-Item -Path $oldExe -Force -ErrorAction SilentlyContinue
                }
            }
        }

        $destExe = Join-Path $extractDir $targetAsset.name
        Copy-Item -LiteralPath $outFile -Destination $destExe -Force
        Write-Status -Level "OK" -Message "已部署執行檔至: $destExe"
    }

    $State[$Item.Repo] = @{
        Tag       = $latestTag
        FileName  = $targetAsset.name
        Folder    = $repoName
        LatestTag = $latestTag
        CheckedAt = (Get-Date).ToString("o")
    }
    Save-GitHubStateFile -DownloadDir $DownloadDir -State $State
}

function Remove-GitHubManagedProject {
    param(
        [hashtable]$Item,
        [string]$ToolsDir,
        [string]$DownloadDir,
        [hashtable]$State
    )
    $repoName   = ($Item.Repo -split '/')[-1]
    $extractDir = Join-Path $ToolsDir $repoName
    $curRecord  = $State[$Item.Repo]

    if (-not (Test-Path $extractDir) -and -not $curRecord) {
        Write-Host "[提示] $($Item.Name) 尚未下載或安裝。" -ForegroundColor DarkGray
        return
    }

    $confirm = (Read-Host "[確認] 確定要刪除 $($Item.Name) ($extractDir 與下載檔) 嗎？(y/N)").Trim()
    if ($confirm -ine "Y") {
        Write-Host "[取消] 未刪除 $($Item.Name)。" -ForegroundColor DarkGray
        return
    }

    if (Test-Path $extractDir) {
        Remove-Item -Path $extractDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Status -Level "WARN" -Message "已移除資料夾: $extractDir"
    }

    if ($curRecord -and $curRecord.FileName) {
        $zipPath = Join-Path $DownloadDir $curRecord.FileName
        if (Test-Path $zipPath) {
            Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
            Write-Status -Level "WARN" -Message "已移除壓縮檔: $zipPath"
        }
    }

    if ($State.ContainsKey($Item.Repo)) {
        $State.Remove($Item.Repo)
        Save-GitHubStateFile -DownloadDir $DownloadDir -State $State
    }
    Write-Status -Level "OK" -Message "$($Item.Name) 已清除完畢。"
}

function Show-GitHubDownloadMenu {
    param([string]$RootDir)
    if (-not (Test-InternetConnection)) { return }

    $cfg  = Get-WinToolConfig -RootDir $RootDir
    $list = $cfg.GitHubList

    if (-not $list -or $list.Count -eq 0) {
        Write-Status -Level "WARN" -Message "config.psd1 中尚未設定任何 GitHubList 項目。"
        Wait-UserPause -Message "<< 按 Enter 繼續 >>"
        return
    }

    $toolsDir    = "C:\Tools"
    $downloadDir = Join-Path $toolsDir "_Download"
    $latestCache = @{}

    # 載入 30 分鐘內的歷史快取，降低 GitHub API Rate Limit 風險
    $initState = Get-GitHubStateFile -DownloadDir $downloadDir
    foreach ($repoKey in $initState.Keys) {
        $rec = $initState[$repoKey]
        if ($rec.LatestTag -and $rec.CheckedAt) {
            try {
                $elapsed = ((Get-Date) - [DateTime]::Parse($rec.CheckedAt)).TotalMinutes
                if ($elapsed -lt 30) {
                    $latestCache[$repoKey] = $rec.LatestTag
                }
            } catch {}
        }
    }

    $div = Get-LineDivider

    Invoke-PagedMenu -Subtitle "GitHub 專案管理中心 (目錄: $toolsDir)" -Items $list -PageSize 6 `
        -RenderHeaderExtra {
            $hdrCol1 = Format-PadRight " 編號 / 專案名稱" 38
            $hdrCol2 = Format-PadRight "已下載版本" 16
            $hdrCol3 = "最新版本 / 狀態"
            Write-Host "$hdrCol1$hdrCol2$hdrCol3" -ForegroundColor DarkGray
            Write-Host $div -ForegroundColor DarkCyan
        } `
        -RenderItem {
            param($item, $idx)
            $state    = Get-GitHubStateFile -DownloadDir $downloadDir
            $repoName = ($item.Repo -split '/')[-1]
            $folderOk = Test-Path (Join-Path $toolsDir $repoName)
            $rec      = $state[$item.Repo]

            $localVer = if ($rec -and $rec.Tag) {
                if ($folderOk) { $rec.Tag } else { "$($rec.Tag)(缺目錄)" }
            } elseif ($folderOk) {
                "已存在(未知版)"
            } else {
                "-"
            }

            $remoteVer = if ($latestCache.ContainsKey($item.Repo)) {
                $latestCache[$item.Repo]
            } elseif ($item.Tag) {
                "指定: $($item.Tag)"
            } else {
                "未檢查"
            }

            $col1 = Format-PadRight (" [{0,2}] {1}" -f ($idx + 1), $item.Name) 38
            $col2 = Format-PadRight $localVer 16

            Write-Host -NoNewline $col1
            Write-Host -NoNewline $col2 -ForegroundColor $(if ($localVer -eq "-") { "DarkGray" } else { "Cyan" })

            if ($latestCache.ContainsKey($item.Repo)) {
                $rTag = $latestCache[$item.Repo]
                if ($rec -and $rec.Tag -eq $rTag -and $folderOk) {
                    Write-Host "$rTag (已是最新)" -ForegroundColor Green
                } elseif ($rec -and $rec.Tag -and $rec.Tag -ne $rTag) {
                    Write-Host "$rTag [有更新!]" -ForegroundColor Yellow
                } else {
                    Write-Host $rTag -ForegroundColor White
                }
            } else {
                Write-Host $remoteVer -ForegroundColor DarkGray
            }

            if ($item.Desc) {
                Write-Host ("      └─ {0}" -f $item.Desc) -ForegroundColor DarkGray
            }
        } `
        -RenderFooterCommands {
            Write-Host $div -ForegroundColor DarkCyan
            $ghLeft1  = Format-PadRight " [數字] 下載 / 更新 (如: 1,2)" 42
            $ghRight1 = "[C] 檢查所有專案最新版本"
            Write-Host "$ghLeft1$ghRight1"

            $ghLeft2  = Format-PadRight " [D 數字] 刪除專案 (如: D 1)" 42
            $ghRight2 = "[O] 開啟資料夾 ($toolsDir)"
            Write-Host "$ghLeft2$ghRight2"
        } `
        -OnCommand {
            param($raw)
            $state = Get-GitHubStateFile -DownloadDir $downloadDir

            if ($raw -ieq "O") {
                if (-not (Test-Path $toolsDir)) { New-Item -Path $toolsDir -ItemType Directory -Force | Out-Null }
                Start-Process explorer.exe $toolsDir
                return
            }

            if ($raw -ieq "C") {
                Write-Host ""
                Write-Status -Level "INFO" -Message "正在向 GitHub API 查詢最新版本..."
                foreach ($item in $list) {
                    try {
                        $rel = Get-GitHubReleaseInfo -Repo $item.Repo -Tag $item.Tag
                        $latestCache[$item.Repo] = $rel.tag_name
                        if (-not $state[$item.Repo]) { $state[$item.Repo] = @{} }
                        $state[$item.Repo].LatestTag = $rel.tag_name
                        $state[$item.Repo].CheckedAt = (Get-Date).ToString("o")
                    } catch {
                        $latestCache[$item.Repo] = "查詢失敗"
                    }
                }
                Save-GitHubStateFile -DownloadDir $downloadDir -State $state
                return
            }

            if ($raw -match '^[Dd]\s*(.+)$') {
                $delTargets = Resolve-MultiSelection -InputStr $Matches[1] -MaxCount $list.Count
                foreach ($idx in $delTargets) {
                    Remove-GitHubManagedProject -Item $list[$idx - 1] -ToolsDir $toolsDir -DownloadDir $downloadDir -State $state
                }
                Wait-UserPause -Message "<< 按 Enter 繼續 >>"
                return
            }

            $indices = Resolve-MultiSelection -InputStr $raw -MaxCount $list.Count
            if ($indices.Count -eq 0) { return }

            foreach ($idx in $indices) {
                try {
                    Invoke-GitHubAssetInstall -Item $list[$idx - 1] -ToolsDir $toolsDir -DownloadDir $downloadDir -State $state
                    if ($state[$list[$idx - 1].Repo]) {
                        $latestCache[$list[$idx - 1].Repo] = $state[$list[$idx - 1].Repo].Tag
                    }
                } catch {
                    Write-Status -Level "ERR" -Message $_.Exception.Message
                }
            }
            Wait-UserPause -Message "<< 作業完成，按 Enter 繼續 >>"
        }
}