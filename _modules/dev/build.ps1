param([string]$RootDir)
$ErrorActionPreference = "Stop"

$modulesDir = Join-Path $RootDir "_modules"
$folderName = Split-Path $RootDir -Leaf
$autoVer    = if ($folderName -match '([\d\.]+)$') { $Matches[1] } else { "0.03" }

$verInput   = (Read-Host "`n請輸入打包版本號 (直接按 Enter 自動帶入目錄版本 $autoVer)").Trim()
$verTag     = if ($verInput) { $verInput } else { $autoVer }

$outName = "W11Tool_$verTag.bat"
$outPath = Join-Path $RootDir $outName

Write-Host "[INFO] 正在動態組裝 Polyglot 單一執行檔 ($outName)..." -ForegroundColor Cyan

$configRaw = Get-Content (Join-Path $modulesDir "config.psd1") -Raw -Encoding UTF8

# 依相依順序動態掃描並封裝所有 .psm1 模組
$psmOrdered = @("utils.psm1", "ui.psm1")
$allPsm = Get-ChildItem -Path $modulesDir -Filter "*.psm1" | Sort-Object {
    $idx = $psmOrdered.IndexOf($_.Name)
    if ($idx -ge 0) { $idx } else { 999 }
}, Name

$sb = New-Object System.Text.StringBuilder

# Polyglot 檔頭
[void]$sb.AppendLine('<# :')
[void]$sb.AppendLine('@echo off')
[void]$sb.AppendLine('chcp 65001 >nul')
[void]$sb.AppendLine('dir /R "%~f0" 2>nul | findstr /I "Zone.Identifier" >nul 2>&1 && (')
[void]$sb.AppendLine('    powershell -NoProfile -ExecutionPolicy Bypass -Command "Unblock-File -Path ''%~f0''"')
[void]$sb.AppendLine(')')
[void]$sb.AppendLine('net session >nul 2>&1')
[void]$sb.AppendLine('if errorlevel 1 (')
[void]$sb.AppendLine('    powershell -NoProfile -Command "Start-Process -FilePath ''%~f0'' -Verb RunAs"')
[void]$sb.AppendLine('    exit /b')
[void]$sb.AppendLine(')')
[void]$sb.AppendLine('set "WIN_TOOL_ROOT=%~dp0"')
[void]$sb.AppendLine('if "%WIN_TOOL_ROOT:~-1%"=="\" set "WIN_TOOL_ROOT=%WIN_TOOL_ROOT:~0,-1%"')
[void]$sb.AppendLine('set "WIN_TOOL_FILE=%~f0"')
[void]$sb.AppendLine('powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& ([ScriptBlock]::Create((Get-Content -LiteralPath $env:WIN_TOOL_FILE -Raw -Encoding UTF8)))"')
[void]$sb.AppendLine('exit /b %ERRORLEVEL%')
[void]$sb.AppendLine('#>')
[void]$sb.AppendLine('')

# 注入全域設定與版本
[void]$sb.AppendLine('$global:WinToolConfig = ' + $configRaw)
[void]$sb.AppendLine('$global:WinToolVersion = "' + $verTag + '"')

# 動態注入所有 .psm1 模組
foreach ($psm in $allPsm) {
    $modName = "WinTool" + (Get-Culture).TextInfo.ToTitleCase($psm.BaseName)
    $psmRaw  = (Get-Content $psm.FullName -Raw -Encoding UTF8) -replace '(?m)^\s*Export-ModuleMember.*$', ''
    $psmB64  = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($psmRaw))
    [void]$sb.AppendLine("`$src_$($psm.BaseName) = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(`"$psmB64`"))")
    [void]$sb.AppendLine("New-Module -Name `"$modName`" -ScriptBlock ([ScriptBlock]::Create(`$src_$($psm.BaseName))) | Import-Module -Force")
}

# 動態注入所有功能 .ps1 腳本 (排除 menu.ps1，最後再放入 menu.ps1)
$featureScripts = Get-ChildItem -Path $modulesDir -Filter "*.ps1" | Where-Object { $_.Name -ne "menu.ps1" } | Sort-Object Name
foreach ($scr in $featureScripts) {
    [void]$sb.AppendLine((Get-Content $scr.FullName -Raw -Encoding UTF8))
}

$menuRaw = Get-Content (Join-Path $modulesDir "menu.ps1") -Raw -Encoding UTF8
$menuRaw = $menuRaw -replace '(?m)^\s*Import-Module.*\.psm1.*$', ''
$menuRaw = $menuRaw -replace '(?s)Get-ChildItem\s+-Path\s+\$PSScriptRoot.*?\}', ''
[void]$sb.AppendLine($menuRaw)

$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($outPath, $sb.ToString(), $utf8WithBom)

$sizeKB = [Math]::Round((Get-Item $outPath).Length / 1KB, 1)
Write-Host "[SUCCESS] 打包完成：$outName ($sizeKB KB)" -ForegroundColor Green