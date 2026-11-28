@{
    # 專案標題與預設版本
    AppName    = "Windows 11 裝機工具箱"
    DefaultVer = "0.3.2"

    # 線上工具庫 (Type 支援: irm_iex / web)
    OnlineTools = @(
        @{
            Name = "Microsoft Activation Scripts (MAS)"
            Url  = "https://get.activated.win"
            Type = "irm_iex"
            Desc = "HWID / Ohook / KMS38 系統與 Office 啟動"
        }
        @{
            Name = "Win11Debloat"
            Url  = "https://debloat.raphi.re/"
            Type = "irm_iex"
            Desc = "移除內建預載軟體、停用遙測、廣告與基礎 AI 功能"
        }
        @{
            Name = "Chris Titus Tech's Windows Utility"
            Url  = "https://christitus.com/win"
            Type = "irm_iex"
            Desc = "系統調校、服務管理與修復工具箱"
        }
    )

    # 常用工具軟體清單
    SoftwareList = @(
        @{ Cat = "遊戲"; Name = "Steam";                        Id = "Valve.Steam";                            Src = "winget" }
        @{ Cat = "工具"; Name = "Firefox";                      Id = "Mozilla.Firefox";                        Src = "winget" }
        @{ Cat = "工具"; Name = "7-Zip";                        Id = "7zip.7zip";                              Src = "winget" }
        @{ Cat = "工具"; Name = "Wintoys";                      Id = "9P8LTPGCBZXD";                           Src = "msstore" }
        @{ Cat = "Google"; Name = "Chrome";                     Id = "Google.Chrome";                          Src = "winget" }
        @{ Cat = "Google"; Name = "Google Drive";               Id = "Google.GoogleDrive";                     Src = "winget" }
        @{ Cat = "Google"; Name = "Chrome Remote Desktop";      Id = "Google.ChromeRemoteDesktopHost";         Src = "winget" }
        @{ Cat = "編輯"; Name = "Notepad++";                    Id = "Notepad++.Notepad++";                    Src = "winget" }
        @{ Cat = "編輯"; Name = "Obsidian";                     Id = "Obsidian.Obsidian";                      Src = "winget" }
        @{ Cat = "編輯"; Name = "Stirling PDF";                 Id = "StirlingTools.StirlingPDF";              Src = "winget" }
        @{ Cat = "媒體"; Name = "VLC";                          Id = "VideoLAN.VLC";                           Src = "winget" }
        @{ Cat = "媒體"; Name = "XnView MP";                    Id = "XnSoft.XnViewMP";                        Src = "winget" }
        @{ Cat = "驅動"; Name = "Logitech G HUB";               Id = "Logitech.GHUB";                          Src = "winget" }
        @{ Cat = "驅動"; Name = "Logitech Options+";            Id = "Logitech.OptionsPlus";                   Src = "winget" }
        @{ Cat = "驅動"; Name = "MSI Center";                   Id = "9NVMNJCR03XV";                           Src = "msstore" }
        @{ Cat = "驅動"; Name = "Razer Central";                Id = "Razer.RazerCentral";                       Src = "winget" }
        @{ Cat = "驅動"; Name = "Display Driver Uninstaller";   Id = "Wagnardsoft.DisplayDriverUninstaller";    Src = "winget" }
        @{ Cat = "驅動"; Name = "NVCleanstall";                 Id = "TechPowerUp.NVCleanstall";                Src = "winget" }
        @{ Cat = "監控"; Name = "CPU-Z";                        Id = "CPUID.CPU-Z";                             Src = "winget" }
        @{ Cat = "監控"; Name = "GPU-Z";                        Id = "TechPowerUp.GPU-Z";                       Src = "winget" }
        @{ Cat = "監控"; Name = "HWMonitor";                    Id = "CPUID.HWMonitor";                         Src = "winget" }
        @{ Cat = "監控"; Name = "CrystalDiskInfo";              Id = "CrystalMarkSOFTWARE.CrystalDiskInfo";     Src = "winget" }
        @{ Cat = "監控"; Name = "HWiNFO";                       Id = "REALiX.HWiNFO";                           Src = "winget" }
        @{ Cat = "美工"; Name = "GIMP";                         Id = "GIMP.GIMP.3";                             Src = "winget" }
        @{ Cat = "美工"; Name = "Krita";                        Id = "KDE.Krita";                               Src = "winget" }
        @{ Cat = "美工"; Name = "Inkscape";                     Id = "Inkscape.Inkscape";                       Src = "winget" }
        @{ Cat = "美工"; Name = "Paint.NET";                    Id = "dotPDN.PaintDotNet";                      Src = "winget" }
        @{ Cat = "美工"; Name = "Blender";                      Id = "BlenderFoundation.Blender";               Src = "winget" }
        @{ Cat = "內建"; Name = "Microsoft 小畫家";             Id = "9PCFS5B6T720";                            Src = "msstore" }
        @{ Cat = "內建"; Name = "Windows 小算盤";               Id = "9WZDNCRFHVN5";                            Src = "msstore" }
        @{ Cat = "內建"; Name = "Microsoft 相片";               Id = "9FZBMKLG03D3";                            Src = "msstore" }
        @{ Cat = "內建"; Name = "剪取工具";                     Id = "9MZ95KL8MR0L";                            Src = "msstore" }
        @{ Cat = "內建"; Name = "Windows 終端機";               Id = "9NBLGGH4MS6B";                            Src = "msstore" }
    )

    # 軟體快捷組合 (對應 SoftwareList 的套件 ID)
    SoftwarePresets = @(
        @{
            Key  = "P1"
            Name = "基礎裝機包 (7-Zip, Chrome, Notepad++, VLC, XnView)"
            Ids  = @("7zip.7zip", "Google.Chrome", "Notepad++.Notepad++", "VideoLAN.VLC", "XnSoft.XnViewMP")
        }
        @{
            Key  = "P2"
            Name = "硬體檢測包 (CPU-Z, GPU-Z, CrystalDiskInfo, HWiNFO)"
            Ids  = @("CPUID.CPU-Z", "TechPowerUp.GPU-Z", "CrystalMarkSOFTWARE.CrystalDiskInfo", "REALiX.HWiNFO")
        }
        @{
            Key  = "P3"
            Name = "內建工具全補齊 (小畫家, 小算盤, 相片, 剪取工具, 終端機)"
            Ids  = @("9PCFS5B6T720", "9WZDNCRFHVN5", "9FZBMKLG03D3", "9MZ95KL8MR0L", "9NBLGGH4MS6B")
        }
    )

    # KMS 伺服器清單
    KmsServers = @(
        "kms.loli.beer", "kms.loli.best", "kms.03k.org", "kms.luody.info",
        "kms.sixyin.com", "kms.cgtsoft.com", "kms.moeyuuko.com", "kms-default.cangshui.net",
        "kms.moerats.com", "kms.ben-zhu.top", "s1.kms.cx", "win.xdym11235.com",
        "kms.akams.cn", "kms.telecom.ac.cn", "kms.beanbang.cn", "kms.mrhao.net",
        "kms8.msguides.com", "kms.000606.xyz", "kms.kmzs123.cn", "kms.bige0.com",
        "kms.litbear.cn", "kms.ddddg.cn"
    )

    # GitHub Releases 工具下載清單
    GitHubList = @(
        @{
            Name    = "balenaEtcher"
            Repo    = "balena-io/etcher"
            Tag     = ""
            Pattern = "balenaEtcher-*-x64.exe"
            Desc    = "跨平台映像檔寫入 USB / SD 卡工具 (免安裝單一執行檔)"
        }
        @{
            Name    = "Ventoy"
            Repo    = "ventoy/Ventoy"
            Tag     = ""
            Pattern = "ventoy-*-windows.zip"
            Desc    = "免重複格式化多重開機 USB 隨身碟製作工具"
        }
        @{
            Name    = "Rufus"
            Repo    = "pbatard/rufus"
            Tag     = ""
            Pattern = "rufus-*p.exe"
            Desc    = "輕量級可開機 USB 隨身碟製作工具 (Portable 版)"
        }
        @{
            Name    = "ConvertZZ"
            Repo    = "flier268/ConvertZZ"
            Tag     = ""
            Pattern = "*ConvertZZ*.zip"
            Desc    = "剪貼簿與檔案繁簡體中文快速轉換工具"
        }
        @{
            Name    = "Locale-Emulator"
            Repo    = "xupefei/Locale-Emulator"
            Tag     = ""
            Pattern = "Locale.Emulator.*.zip"
            Desc    = "模擬系統語系與時區執行日文/非 Unicode 軟體"
        }
        @{
            Name    = "LunaTranslator"
            Repo    = "HIllya51/LunaTranslator"
            Tag     = ""
            Pattern = "LunaTranslator.zip"
            Desc    = "Galgame/視覺小說 Hook、OCR 與即時翻譯器"
        }
        @{
            Name    = "WindowTranslator"
            Repo    = "Freeesia/WindowTranslator"
            Tag     = ""
            Pattern = "*win-x64*.zip"
            Desc    = "即時螢幕視窗 OCR 擷取與多語言翻譯工具"
        }
        @{
            Name    = "Magpie"
            Repo    = "Blinue/Magpie"
            Tag     = ""
            Pattern = "Magpie-v*-x64.zip"
            Desc    = "視窗化遊戲與軟體通用無損縮放/補幀放大工具"
        }
        @{
            Name    = "ImageGlass"
            Repo    = "d2phap/ImageGlass"
            Tag     = ""
            Pattern = "*win*x64*.zip"
            Desc    = "輕量開源的圖片檢視器（支援多種影像格式）"
        }
    )
}