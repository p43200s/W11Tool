$global:ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

$script:NetChecked      = $false
$script:WinGetChecked   = $false
$script:SysSummaryCache = $null
$script:InstalledIdSet  = $null

function Get-WinToolConfig {
    param([string]$RootDir = $env:WIN_TOOL_ROOT)
    if ($global:WinToolConfig) { return $global:WinToolConfig }
    $global:WinToolConfig = Import-PowerShellDataFile (Join-Path $RootDir "_modules\config.psd1")
    return $global:WinToolConfig
}

function Get-AppVersion {
    param([string]$RootDir = $env:WIN_TOOL_ROOT)
    if ($global:WinToolVersion) { return $global:WinToolVersion }

    $folderName = if ($RootDir) { Split-Path $RootDir -Leaf } else { "" }
    if ($folderName -match '([\d\.]+)$') {
        $global:WinToolVersion = $Matches[1]
    } else {
        $cfg = Get-WinToolConfig -RootDir $RootDir
        $global:WinToolVersion = if ($cfg.DefaultVer) { $cfg.DefaultVer } else { "0.03" }
    }
    return $global:WinToolVersion
}

function Get-SystemSummary {
    if ($script:SysSummaryCache) { return $script:SysSummaryCache }

    try {
        $osInfo  = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue
        $edition = ($osInfo.ProductName -replace 'Windows ', 'Win' -replace 'Enterprise', 'Ent' -replace 'Professional', 'Pro')
        if ($osInfo.CurrentBuildNumber -ge 22000) { $edition = $edition -replace 'Win10', 'Win11' }
        $dispVer = if ($osInfo.DisplayVersion) { $osInfo.DisplayVersion } else { "" }
        $build   = $osInfo.CurrentBuildNumber

        $cpuRaw  = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1).Name
        $cpuName = ($cpuRaw -replace '\(R\)|\(TM\)|CPU|Processor|@.*|with Radeon.*|\d+-Core', '' -replace '\s+', ' ').Trim()
        if ($cpuName.Length -gt 30) { $cpuName = $cpuName.Substring(0, 30).Trim() }

        # 讀取主機板廠牌與型號，並精簡常見 OEM 廠牌全名
        $mbInfo = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue | Select-Object -First 1
        $mfgRaw = if ($mbInfo.Manufacturer) { $mbInfo.Manufacturer.Trim() } else { "" }
        $mfg = switch -Regex ($mfgRaw) {
            'ASUSTeK'    { 'ASUS'; break }
            'Micro-Star' { 'MSI'; break }
            'Gigabyte'   { 'Gigabyte'; break }
            'ASRock'     { 'ASRock'; break }
            'BIOSTAR'    { 'BIOSTAR'; break }
            'Colorful'   { 'Colorful'; break }
            'Dell'       { 'Dell'; break }
            'Hewlett|HP' { 'HP'; break }
            'Lenovo'     { 'Lenovo'; break }
            'Acer'       { 'Acer'; break }
            default      { ($mfgRaw -replace 'To be filled by O\.E\.M\.|Default string|System manufacturer', '').Trim() }
        }

        $prodRaw = if ($mbInfo.Product) { $mbInfo.Product } else { "未知型號" }
        $prod    = ($prodRaw -replace 'To be filled by O\.E\.M\.|Default string|System Product Name', '未知型號' -replace '\s+', ' ').Trim()

        # 若廠牌存在且型號開頭尚未包含該廠牌（如 ASUS / ROG / TUF），則自動補上廠牌前綴
        $mbName = if ($mfg -and $prod -ne "未知型號" -and $prod -notmatch "^($mfg|ROG|TUF|MAG|MPG|MEG|PRO)\b") {
            "$mfg $prod"
        } else {
            $prod
        }
        if ($mbName.Length -gt 28) { $mbName = $mbName.Substring(0, 28).Trim() }

        $ramBytes = (Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue).TotalPhysicalMemory
        $ramGB    = if ($ramBytes) { [Math]::Round($ramBytes / 1GB) } else { 0 }

        $script:SysSummaryCache = @{
            Line1 = "CPU: $cpuName │ MB: $mbName │ RAM: ${ramGB}GB"
            Line2 = "OS: $edition $dispVer ($build)"
        }
    } catch {
        $script:SysSummaryCache = @{
            Line1 = "CPU: 未知 │ MB: 未知 │ RAM: 未知"
            Line2 = "OS: Windows 11"
        }
    }
    return $script:SysSummaryCache
}

function Resolve-MultiSelection {
    param(
        [string]$InputStr,
        [int]$MaxCount
    )
    $selected = [System.Collections.Generic.List[int]]::new()
    $tokens = $InputStr -split '[,\s]+' | Where-Object { $_ -ne "" }

    foreach ($t in $tokens) {
        if ($t -match '^(\d+)-(\d+)$') {
            $start = [int]$Matches[1]
            $end   = [int]$Matches[2]
            if ($start -le $end) {
                for ($n = $start; $n -le $end; $n++) {
                    if ($n -ge 1 -and $n -le $MaxCount -and -not $selected.Contains($n)) {
                        $selected.Add($n)
                    }
                }
            }
        } elseif ($t -match '^\d+$') {
            $n = [int]$t
            if ($n -ge 1 -and $n -le $MaxCount -and -not $selected.Contains($n)) {
                $selected.Add($n)
            }
        }
    }
    return $selected.ToArray()
}

function Test-InternetConnection {
    param([switch]$Silent)
    if ($script:NetChecked) { return $true }

    $endpoints = @(
        @{ Host = "1.1.1.1"; Port = 443 },
        @{ Host = "8.8.8.8"; Port = 53 },
        @{ Host = "223.5.5.5"; Port = 53 }
    )

    foreach ($ep in $endpoints) {
        $tcp = New-Object System.Net.Sockets.TcpClient
        try {
            $iar = $tcp.BeginConnect($ep.Host, $ep.Port, $null, $null)
            if ($iar.AsyncWaitHandle.WaitOne(1200, $false) -and $tcp.Connected) {
                $tcp.EndConnect($iar)
                $script:NetChecked = $true
                return $true
            }
        } catch {
            # 嘗試下一個節點
        } finally {
            $tcp.Close()
        }
    }

    if (-not $Silent) {
        Write-Host "`n[ERR] 無法連線至網際網路，請檢查網路設定。" -ForegroundColor Red
        Wait-UserPause -Message "<< 按 Enter 繼續 >>"
    }
    return $false
}

function Confirm-WinGetReady {
    if ($script:WinGetChecked) { return $true }
    Write-Host "[INFO] 驗證 WinGet 套件管理員..." -ForegroundColor DarkGray

    $wg = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wg) {
        Write-Host "[FIX] 嘗試重新註冊 App Installer..." -ForegroundColor Yellow
        Get-AppxPackage -AllUsers Microsoft.DesktopAppInstaller | ForEach-Object {
            Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $_.InstallLocation "AppXManifest.xml") -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
        $wg = Get-Command winget -ErrorAction SilentlyContinue
    }

    if (-not $wg) {
        Write-Host "[ERR] WinGet 無法使用，請至 Microsoft Store 更新「應用程式安裝程式 (App Installer)」。" -ForegroundColor Red
        Wait-UserPause -Message "<< 按 Enter 繼續 >>"
        return $false
    }

    winget source list >$null 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FIX] 重置並更新 WinGet 來源..." -ForegroundColor Yellow
        winget source reset --force >$null 2>&1
        winget source update >$null 2>&1
    }

    $script:WinGetChecked = $true
    return $true
}

function Get-InstalledWinGetIds {
    param([switch]$ForceRefresh)
    if ($script:InstalledIdSet -and -not $ForceRefresh) {
        return $script:InstalledIdSet
    }

    $set = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    try {
        $rawList = winget list --accept-source-agreements 2>$null
        foreach ($line in $rawList) {
            # 擷取標準套件 ID (包含點號如 Valve.Steam 或 12 碼英數 MSStore ID 如 9P8LTPGCBZXD)
            if ($line -match '\s([A-Za-z0-9\-\+]+(?:\.[A-Za-z0-9\-\+]+)+|9[A-Z0-9]{11})\s') {
                [void]$set.Add($Matches[1])
            }
        }
    } catch {
        # 忽略掃描異常，回傳空集合不影響安裝流程
    }
    $script:InstalledIdSet = $set
    return $set
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWord"
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

Export-ModuleMember -Function Get-WinToolConfig, Get-AppVersion, Get-SystemSummary, Resolve-MultiSelection, Test-InternetConnection, Confirm-WinGetReady, Get-InstalledWinGetIds, Set-RegistryValue