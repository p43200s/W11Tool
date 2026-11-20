$script:DefenderStateCache = $null

function Set-ContextMenuStyle {
    param([bool]$Classic)
    $clsids = @(
        "{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}",
        "{51668040-5e31-4023-bbe3-149163bd80f1}"
    )

    foreach ($id in $clsids) {
        $regPath = "HKCU:\Software\Classes\CLSID\$id"
        if ($Classic) {
            Set-RegistryValue -Path "$regPath\InprocServer32" -Name "(Default)" -Value "" -Type "String"
        } else {
            if (Test-Path $regPath) {
                Remove-Item -Path $regPath -Recurse -Force
            }
        }
    }

    if ($Classic) {
        Write-Status -Level "OK" -Message "已切換為「傳統右鍵風格 (支援 Win11 26H2)」"
    } else {
        Write-Status -Level "OK" -Message "已還原為「新版 Win11 右鍵風格」"
    }

    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe
}

function Enable-UltimatePerformance {
    $templateGuid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
    $listOut = powercfg /list
    $match = $listOut | Select-String -Pattern "([a-f0-9\-]{36}).*(Ultimate|終極效能)"

    if ($match) {
        $guid = $match.Matches[0].Groups[1].Value
        Write-Status -Level "INFO" -Message "找到現有終極效能計畫: $guid"
    } else {
        $dupOut = powercfg -duplicatescheme $templateGuid
        if ($dupOut -match "([a-f0-9\-]{36})") {
            $guid = $Matches[1]
            Write-Status -Level "INFO" -Message "已建立終極效能計畫: $guid"
        } else {
            Write-Status -Level "ERR" -Message "建立電源計畫失敗。"
            return
        }
    }

    powercfg -setactive $guid
    if ($LASTEXITCODE -eq 0) {
        Write-Status -Level "OK" -Message "已啟用「終極效能」電源計畫！"
    } else {
        Write-Status -Level "WARN" -Message "無法自動啟用，正在開啟控制台供手動選擇..."
        Start-Process control.exe -ArgumentList "powercfg.cpl"
    }
}

function Remove-XboxGameBar {
    Write-Status -Level "STEP" -Message "[1/3] 移除 Xbox Game Bar 套件..."
    Get-AppxPackage -AllUsers Microsoft.XboxGamingOverlay | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq 'Microsoft.XboxGamingOverlay' } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

    Write-Status -Level "STEP" -Message "[2/3] 修復 ms-gamebar 協定關聯..."
    if (-not (Test-Path "HKCR:")) {
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
    }
    foreach ($proto in @("ms-gamebar", "ms-gamebarservices")) {
        Set-RegistryValue -Path "HKCR:\$proto" -Name "(Default)" -Value "URL:$proto" -Type "String"
        Set-RegistryValue -Path "HKCR:\$proto" -Name "URL Protocol" -Value "" -Type "String"
        Set-RegistryValue -Path "HKCR:\$proto" -Name "NoOpenWith" -Value "" -Type "String"
        Set-RegistryValue -Path "HKCR:\$proto\shell\open\command" -Name "(Default)" -Value "$env:SystemRoot\System32\systray.exe" -Type "String"
    }

    Write-Status -Level "STEP" -Message "[3/3] 停用 Game DVR..."
    Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type "DWord"
    Set-RegistryValue -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type "DWord"
    Write-Status -Level "OK" -Message "Xbox Game Bar 已徹底移除！"
}

function Get-DefenderRealtimeState {
    param([switch]$ForceRefresh)
    if ($null -ne $script:DefenderStateCache -and -not $ForceRefresh) {
        return $script:DefenderStateCache
    }

    try {
        $mpStatus = Get-MpComputerStatus -ErrorAction Stop
        $script:DefenderStateCache = [bool]$mpStatus.RealTimeProtectionEnabled
    } catch {
        $regVal = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -ErrorAction SilentlyContinue).DisableRealtimeMonitoring
        $script:DefenderStateCache = ($regVal -ne 1)
    }
    return $script:DefenderStateCache
}

function Open-DefenderThreatSettings {
    try {
        Start-Process "windowsdefender://threatsettings/" -ErrorAction Stop
    } catch {
        Start-Process "ms-settings:windowsdefender"
    }
}

function Switch-DefenderRealtimeProtection {
    $isEnabled = Get-DefenderRealtimeState -ForceRefresh
    $targetDisable = $isEnabled

    if ($targetDisable) {
        $tamperEnabled = $false
        try {
            $mpStatus = Get-MpComputerStatus -ErrorAction Stop
            if ($mpStatus.IsTamperProtected -eq $true) { $tamperEnabled = $true }
        } catch {
            $tpReg = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TamperProtection" -ErrorAction SilentlyContinue).TamperProtection
            if ($tpReg -in @(1, 5)) { $tamperEnabled = $true }
        }

        if ($tamperEnabled) {
            Write-Host ""
            Write-Status -Level "WARN" -Message "偵測到 Windows 安全性「竄改防護」目前為開啟狀態！"
            Write-Host "       由於系統安全機制限制，腳本無法直接關閉即時掃描。" -ForegroundColor Gray
            Write-Host "`n請在即將開啟的「病毒與威脅防護設定」視窗中：" -ForegroundColor Cyan
            Write-Host "  1. 將「即時保護」切換為關閉"
            Write-Host "  2. 往下捲動將「竄改防護」切換為關閉（方便後續腳本直接控制）"
            Write-Host "`n[提示] 3 秒後將自動開啟設定視窗..." -ForegroundColor DarkGray
            Start-Sleep -Seconds 3
            Open-DefenderThreatSettings
            $script:DefenderStateCache = $null
            return
        }
    }

    try {
        Set-MpPreference -DisableRealtimeMonitoring $targetDisable -ErrorAction Stop
        $script:DefenderStateCache = (-not $targetDisable)
        Write-Host ""
        if ($targetDisable) {
            Write-Status -Level "WARN" -Message "已關閉 Windows 安全性「即時保護」掃描！"
        } else {
            Write-Status -Level "OK" -Message "已重新開啟 Windows 安全性「即時保護」掃描！"
        }
    } catch {
        Write-Host ""
        Write-Status -Level "ERR" -Message "變更即時保護狀態失敗：$($_.Exception.Message)"
        Write-Host "[提示] 3 秒後將自動開啟「病毒與威脅防護設定」視窗..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        Open-DefenderThreatSettings
        $script:DefenderStateCache = $null
    }
}

function Show-TweaksMenu {
    $items = @(
        @{ Key = "1"; Label = "滑鼠右鍵 › 傳統風格 (支援 Win11 26H2)"; Action = { Set-ContextMenuStyle -Classic $true } }
        @{ Key = "2"; Label = "滑鼠右鍵 › Win11 新版風格";            Action = { Set-ContextMenuStyle -Classic $false } }
        @{ Key = "3"; Label = "電源計畫 › 開啟「終極效能」";           Action = { Enable-UltimatePerformance } }
        @{ Key = "4"; Label = "遊戲元件 › 移除 Xbox Game Bar 並修復連結"; Action = { Remove-XboxGameBar } }
    )
    Invoke-MenuLoop -Subtitle "系統調校與註冊表" -MenuItems $items
}