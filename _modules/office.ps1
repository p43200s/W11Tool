function Get-OfficeXmlContent {
    param([string]$Type)
    $commonSettings = @"
  <Updates Enabled="TRUE" />
  <RemoveMSI />
  <AppSettings>
    <User Key="software\microsoft\office\16.0\excel\options" Name="defaultformat" Value="51" Type="REG_DWORD" App="excel16" Id="L_SaveExcelfilesas" />
    <User Key="software\microsoft\office\16.0\powerpoint\options" Name="defaultformat" Value="27" Type="REG_DWORD" App="ppt16" Id="L_SavePowerPointfilesas" />
    <User Key="software\microsoft\office\16.0\word\options" Name="defaultformat" Value="" Type="REG_SZ" App="word16" Id="L_SaveWordfilesas" />
  </AppSettings>
  <Display Level="Full" AcceptEULA="TRUE" />
</Configuration>
"@

    switch ($Type) {
        "2024_STD" {
            return @"
<Configuration ID="7d7fa3a6-64c5-4adb-b498-a794f1482228">
  <Add OfficeClientEdition="64" Channel="PerpetualVL2024">
    <Product ID="Standard2024Volume" PIDKEY="V28N4-JG22K-W66P8-VTMGK-H6HGR">
      <Language ID="zh-tw" />
      <ExcludeApp ID="Groove" /><ExcludeApp ID="Lync" /><ExcludeApp ID="OneDrive" />
      <ExcludeApp ID="OneNote" /><ExcludeApp ID="Outlook" /><ExcludeApp ID="OutlookForWindows" /><ExcludeApp ID="Publisher" />
    </Product>
  </Add>
  <Property Name="SharedComputerLicensing" Value="0" /><Property Name="FORCEAPPSHUTDOWN" Value="FALSE" />
  <Property Name="DeviceBasedLicensing" Value="0" /><Property Name="SCLCacheOverride" Value="0" /><Property Name="AUTOACTIVATE" Value="1" />
  <Updates Enabled="FALSE" />
  <RemoveMSI />
  <Display Level="Full" AcceptEULA="TRUE" />
</Configuration>
"@
        }
        "365_BUS" {
            return @"
<Configuration ID="7d805074-b541-4d82-aa7a-2e9b26b7e9eb">
  <Add OfficeClientEdition="64" Channel="Current">
    <Product ID="O365BusinessEEANoTeamsRetail">
      <Language ID="zh-tw" />
      <ExcludeApp ID="Groove" /><ExcludeApp ID="Lync" /><ExcludeApp ID="OneDrive" />
      <ExcludeApp ID="OneNote" /><ExcludeApp ID="Outlook" /><ExcludeApp ID="OutlookForWindows" /><ExcludeApp ID="Publisher" />
    </Product>
  </Add>
$commonSettings
"@
        }
        "365_HOME" {
            return @"
<Configuration ID="7d805074-b541-4d82-aa7a-2e9b26b7e9eb">
  <Add OfficeClientEdition="64" Channel="Current">
    <Product ID="O365HomePremRetail">
      <Language ID="zh-tw" />
      <ExcludeApp ID="Access" /><ExcludeApp ID="Bing" /><ExcludeApp ID="Groove" /><ExcludeApp ID="Lync" />
      <ExcludeApp ID="OneDrive" /><ExcludeApp ID="OneNote" /><ExcludeApp ID="Outlook" /><ExcludeApp ID="Publisher" /><ExcludeApp ID="Teams" />
    </Product>
  </Add>
$commonSettings
"@
        }
        "REMOVE_APPS" {
            $regVal = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -Name "ProductReleaseIds" -ErrorAction SilentlyContinue).ProductReleaseIds
            $productId = if ($regVal) { ($regVal -split ',')[0] } else { "O365HomePremRetail" }
            Write-Status -Level "INFO" -Message "偵測到目前產品 ID: $productId"
            return @"
<Configuration>
  <Add Version="MatchInstalled">
    <Product ID="$productId">
      <Language ID="MatchInstalled" TargetProduct="All" />
      <ExcludeApp ID="Access" /><ExcludeApp ID="Bing" /><ExcludeApp ID="Groove" /><ExcludeApp ID="Lync" />
      <ExcludeApp ID="OneDrive" /><ExcludeApp ID="OneNote" /><ExcludeApp ID="Outlook" /><ExcludeApp ID="Publisher" /><ExcludeApp ID="Teams" />
    </Product>
  </Add>
  <Display Level="Full" AcceptEULA="TRUE" />
</Configuration>
"@
        }
    }
}

function Invoke-OfficeDeploy {
    param([string]$RootDir, [string]$Type, [bool]$SkipDownload = $false)
    $setupExe = Join-Path $RootDir "setup.exe"

    if (-not (Test-Path $setupExe)) {
        Write-Status -Level "INFO" -Message "找不到 setup.exe，正在從微軟官網取得最新版 ODT..."
        $resp = Invoke-WebRequest -Uri "https://www.microsoft.com/en-us/download/details.aspx?id=49117" -UseBasicParsing
        $link = ($resp.Links | Where-Object { $_.href -match 'officedeploymenttool_.*\.exe' } | Select-Object -First 1).href
        if (-not $link) { throw "無法解析 ODT 下載網址。" }

        $tmpInstaller = Join-Path $env:TEMP "odt_installer.exe"
        & curl.exe -L -s "$link" -o "$tmpInstaller"
        Start-Process -FilePath $tmpInstaller -ArgumentList "/extract:`"$RootDir`" /quiet" -Wait
        Remove-Item $tmpInstaller -Force -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $RootDir "configuration*.xml") -Force -ErrorAction SilentlyContinue
    }

    $xmlPath = Join-Path $env:TEMP "office_cfg_$(Get-Random).xml"
    $xmlBody = Get-OfficeXmlContent -Type $Type
    [System.IO.File]::WriteAllText($xmlPath, $xmlBody, (New-Object System.Text.UTF8Encoding $false))

    try {
        if (-not $SkipDownload) {
            Write-Status -Level "STEP" -Message "[1/2] 正在下載 Office 安裝檔案（請稍候）..."
            Start-Process -FilePath $setupExe -ArgumentList "/download `"$xmlPath`"" -Wait
        }
        Write-Status -Level "STEP" -Message "[2/2] 正在執行 Office 安裝與設定..."
        Start-Process -FilePath $setupExe -ArgumentList "/configure `"$xmlPath`"" -Wait
        Write-Status -Level "OK" -Message "Office 作業已順利結束！"
    } finally {
        Remove-Item $xmlPath -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-OfficeKmsActivate {
    param([string]$RootDir)
    $cfg = Get-WinToolConfig -RootDir $RootDir
    $ospp = @(
        "$env:ProgramFiles\Microsoft Office\Office16\ospp.vbs",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office16\ospp.vbs"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $ospp) {
        Write-Status -Level "ERR" -Message "找不到 ospp.vbs，請確認已安裝 Office。"
        return
    }

    foreach ($srv in $cfg.KmsServers) {
        Write-Host "[嘗試] 連線 KMS 伺服器: $srv ..." -ForegroundColor DarkGray
        cscript //nologo "$ospp" /sethst:$srv >$null
        $actOut = cscript //nologo "$ospp" /act
        if ($actOut -match "successful") {
            Write-Host ""
            Write-Status -Level "OK" -Message "Office 已透過 $srv 啟動完成！"
            cscript //nologo "$ospp" /dstatus | Select-String -Pattern "LICENSE NAME|LICENSE STATUS|REMAINING"
            return
        }
    }
    Write-Host ""
    Write-Status -Level "ERR" -Message "所有 KMS 伺服器皆無法完成啟動。"
}

function Show-OfficeMenu {
    param([string]$RootDir)
    if (-not (Test-InternetConnection)) { return }

    $items = @(
        @{ Key = "1"; Label = "安裝 Office 2024 Standard";                        Action = { Invoke-OfficeDeploy -RootDir $RootDir -Type "2024_STD" } }
        @{ Key = "2"; Label = "啟動 Office 2024 Standard (自動 KMS)";             Action = { Invoke-OfficeKmsActivate -RootDir $RootDir } }
        @{ Key = "3"; Label = "安裝 Office 365 Home";                             Action = { Invoke-OfficeDeploy -RootDir $RootDir -Type "365_HOME" } }
        @{ Key = "4"; Label = "安裝 Office 365 Business";                         Action = { Invoke-OfficeDeploy -RootDir $RootDir -Type "365_BUS" } }
        @{ Key = "5"; Label = "精簡已安裝的 Office 元件 (移除 OneDrive/Teams 等)";  Action = { Invoke-OfficeDeploy -RootDir $RootDir -Type "REMOVE_APPS" -SkipDownload $true } }
        @{ Key = "6"; Label = "開啟微軟官方 XML 自訂工具網頁";                      Action = { Start-Process "https://config.office.com/deploymentsettings" }; NoPause = $true }
    )
    Invoke-MenuLoop -Subtitle "Office 部署與啟動" -MenuItems $items
}