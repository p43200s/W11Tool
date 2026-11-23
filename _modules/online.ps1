function Invoke-OnlineToolItem {
    param([hashtable]$Tool)

    Show-Header -Subtitle "線上工具執行 › $($Tool.Name)"
    Write-Status -Level "INFO" -Message "目標來源：$($Tool.Url)"
    if ($Tool.Desc) {
        Write-Host "       用途說明：$($Tool.Desc)" -ForegroundColor DarkGray
    }
    Write-Host ""

    if ($Tool.Type -eq "web") {
        Start-Process $Tool.Url
        Write-Status -Level "OK" -Message "已在預設瀏覽器開啟網頁。"
        return
    }

    $confirm = (Read-Host "確定要從網路即時載入並執行此腳本嗎？(Y/n)").Trim()
    if ($confirm -ne "" -and $confirm -ine "Y") {
        Write-Status -Level "WARN" -Message "已取消執行。"
        return
    }

    Write-Host ""
    Write-Status -Level "STEP" -Message "正在連線取得腳本..."
    $scriptContent = Invoke-RestMethod -Uri $Tool.Url -TimeoutSec 20 -ErrorAction Stop
    & ([scriptblock]::Create($scriptContent))
}

function Show-OnlineToolsMenu {
    param([string]$RootDir)
    if (-not (Test-InternetConnection)) { return }

    $cfg  = Get-WinToolConfig -RootDir $RootDir
    $list = $cfg.OnlineTools

    if (-not $list -or $list.Count -eq 0) {
        Write-Status -Level "WARN" -Message "config.psd1 中尚未設定任何 OnlineTools 項目。"
        Wait-UserPause -Message "<< 按 Enter 繼續 >>"
        return
    }

    Invoke-PagedMenu -Subtitle "線上工具庫 (即時拉取執行)" -Items $list -PageSize 6 `
        -RenderItem {
            param($t, $idx)
            Write-Host (" [{0,2}] {1}" -f ($idx + 1), $t.Name) -ForegroundColor White
            if ($t.Desc) {
                $hostDomain = ([uri]$t.Url).Host
                Write-Host ("      └─ {0} ({1})" -f $t.Desc, $hostDomain) -ForegroundColor DarkGray
            }
        } `
        -OnCommand {
            param($raw)
            if ($raw -match '^\d+$') {
                $idx = [int]$raw
                if ($idx -ge 1 -and $idx -le $list.Count) {
                    try {
                        Invoke-OnlineToolItem -Tool $list[$idx - 1]
                    } catch {
                        Write-Status -Level "ERR" -Message "執行失敗：$($_.Exception.Message)"
                    }
                    Wait-UserPause -Message "<< 按 Enter 繼續 >>"
                }
            }
        }
}