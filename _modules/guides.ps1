function Show-NVCleanstallGuide {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="NVCleanstall 中文說明對照表" Height="720" Width="760"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="#E0E0E0"
        FontFamily="Microsoft JhengHei UI, Segoe UI" FontSize="13.5">
    <Grid Margin="14">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0" Background="#252526" BorderBrush="#3E3E42" BorderThickness="1" CornerRadius="4" Padding="10" Margin="0,0,0,10">
            <StackPanel Orientation="Horizontal">
                <TextBlock Text="圖例說明：" FontWeight="Bold" Foreground="#CCCCCC" Margin="0,0,12,0"/>
                <TextBlock Text="● [必勾] 核心必備" Foreground="#4EC9B0" FontWeight="Bold" Margin="0,0,14,0"/>
                <TextBlock Text="● [建議] 推薦勾選" Foreground="#569CD6" FontWeight="Bold" Margin="0,0,14,0"/>
                <TextBlock Text="● [依需求] 視硬體決定" Foreground="#DCDCAA" Margin="0,0,14,0"/>
                <TextBlock Text="● [勿勾] 勾選會異常" Foreground="#F44747" FontWeight="Bold"/>
            </StackPanel>
        </Border>

        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="0,0,6,0">
            <StackPanel>
                <!-- 第一部分 -->
                <TextBlock Text="一、 元件選擇 (Select Components)" FontSize="16" FontWeight="Bold" Foreground="#4FC1FF" Margin="0,4,0,8"/>
                <DataGrid Name="Grid1" AutoGenerateColumns="False" IsReadOnly="True" HeadersVisibility="Column"
                          Background="#252526" RowBackground="#252526" AlternatingRowBackground="#2D2D30"
                          Foreground="#E0E0E0" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#3E3E42"
                          BorderBrush="#3E3E42" CanUserResizeRows="False" SelectionMode="Single" Margin="0,0,0,16">
                    <DataGrid.Resources>
                        <Style TargetType="DataGridColumnHeader">
                            <Setter Property="Background" Value="#333337"/>
                            <Setter Property="Foreground" Value="#FFFFFF"/>
                            <Setter Property="FontWeight" Value="Bold"/>
                            <Setter Property="Padding" Value="8,6"/>
                        </Style>
                        <Style TargetType="DataGridCell">
                            <Setter Property="Padding" Value="8,5"/>
                            <Setter Property="Template">
                                <Setter.Value>
                                    <ControlTemplate TargetType="DataGridCell">
                                        <Border Padding="{TemplateBinding Padding}" Background="{TemplateBinding Background}">
                                            <ContentPresenter VerticalAlignment="Center"/>
                                        </Border>
                                    </ControlTemplate>
                                </Setter.Value>
                            </Setter>
                        </Style>
                    </DataGrid.Resources>
                    <DataGrid.Columns>
                        <DataGridTextColumn Header="英文選項" Binding="{Binding Name}" Width="230" FontWeight="SemiBold"/>
                        <DataGridTextColumn Header="建議" Binding="{Binding Tag}" Width="65">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="Foreground" Value="{Binding Color}"/>
                                    <Setter Property="FontWeight" Value="Bold"/>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="中文功能說明" Binding="{Binding Desc}" Width="*"/>
                    </DataGrid.Columns>
                </DataGrid>

                <!-- 第二部分 -->
                <TextBlock Text="二、 安裝微調 (Installation Tweaks)" FontSize="16" FontWeight="Bold" Foreground="#4FC1FF" Margin="0,4,0,8"/>
                <DataGrid Name="Grid2" AutoGenerateColumns="False" IsReadOnly="True" HeadersVisibility="Column"
                          Background="#252526" RowBackground="#252526" AlternatingRowBackground="#2D2D30"
                          Foreground="#E0E0E0" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#3E3E42"
                          BorderBrush="#3E3E42" CanUserResizeRows="False" SelectionMode="Single" Margin="0,0,0,16">
                    <DataGrid.Resources>
                        <Style TargetType="DataGridColumnHeader">
                            <Setter Property="Background" Value="#333337"/>
                            <Setter Property="Foreground" Value="#FFFFFF"/>
                            <Setter Property="FontWeight" Value="Bold"/>
                            <Setter Property="Padding" Value="8,6"/>
                        </Style>
                        <Style TargetType="DataGridCell">
                            <Setter Property="Padding" Value="8,5"/>
                            <Setter Property="Template">
                                <Setter.Value>
                                    <ControlTemplate TargetType="DataGridCell">
                                        <Border Padding="{TemplateBinding Padding}" Background="{TemplateBinding Background}">
                                            <ContentPresenter VerticalAlignment="Center"/>
                                        </Border>
                                    </ControlTemplate>
                                </Setter.Value>
                            </Setter>
                        </Style>
                    </DataGrid.Resources>
                    <DataGrid.Columns>
                        <DataGridTextColumn Header="英文選項" Binding="{Binding Name}" Width="260" FontWeight="SemiBold"/>
                        <DataGridTextColumn Header="建議" Binding="{Binding Tag}" Width="65">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="Foreground" Value="{Binding Color}"/>
                                    <Setter Property="FontWeight" Value="Bold"/>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="中文功能說明" Binding="{Binding Desc}" Width="*"/>
                    </DataGrid.Columns>
                </DataGrid>

                <!-- 第三部分 -->
                <TextBlock Text="三、 進階專家微調 (Show Expert Tweaks)" FontSize="16" FontWeight="Bold" Foreground="#4FC1FF" Margin="0,4,0,8"/>
                <DataGrid Name="Grid3" AutoGenerateColumns="False" IsReadOnly="True" HeadersVisibility="Column"
                          Background="#252526" RowBackground="#252526" AlternatingRowBackground="#2D2D30"
                          Foreground="#E0E0E0" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#3E3E42"
                          BorderBrush="#3E3E42" CanUserResizeRows="False" SelectionMode="Single" Margin="0,0,0,8">
                    <DataGrid.Resources>
                        <Style TargetType="DataGridColumnHeader">
                            <Setter Property="Background" Value="#333337"/>
                            <Setter Property="Foreground" Value="#FFFFFF"/>
                            <Setter Property="FontWeight" Value="Bold"/>
                            <Setter Property="Padding" Value="8,6"/>
                        </Style>
                        <Style TargetType="DataGridCell">
                            <Setter Property="Padding" Value="8,5"/>
                            <Setter Property="Template">
                                <Setter.Value>
                                    <ControlTemplate TargetType="DataGridCell">
                                        <Border Padding="{TemplateBinding Padding}" Background="{TemplateBinding Background}">
                                            <ContentPresenter VerticalAlignment="Center"/>
                                        </Border>
                                    </ControlTemplate>
                                </Setter.Value>
                            </Setter>
                        </Style>
                    </DataGrid.Resources>
                    <DataGrid.Columns>
                        <DataGridTextColumn Header="英文選項" Binding="{Binding Name}" Width="280" FontWeight="SemiBold"/>
                        <DataGridTextColumn Header="建議" Binding="{Binding Tag}" Width="65">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="Foreground" Value="{Binding Color}"/>
                                    <Setter Property="FontWeight" Value="Bold"/>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="中文功能說明" Binding="{Binding Desc}" Width="*"/>
                    </DataGrid.Columns>
                </DataGrid>
            </StackPanel>
        </ScrollViewer>

        <DockPanel Grid.Row="2" Margin="0,10,0,0">
            <TextBlock Text="💡 提示：勾選完畢後，可點 NVCleanstall 左下角「Save Settings」存成 .ini 檔供下次自動載入。"
                       Foreground="#AAAAAA" VerticalAlignment="Center"/>
            <Button Name="BtnClose" Content="關閉視窗 (Esc)" Width="120" Height="30" HorizontalAlignment="Right"
                    Background="#0E639C" Foreground="White" BorderThickness="0" FontWeight="Bold" Cursor="Hand"/>
        </DockPanel>
    </Grid>
</Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [Windows.Markup.XamlReader]::Load($reader)

    $cReq  = "#4EC9B0" # 必勾
    $cRec  = "#569CD6" # 建議
    $cOpt  = "#DCDCAA" # 依需求
    $cSkip = "#808080" # 不勾
    $cWarn = "#F44747" # 勿勾

    $window.FindName("Grid1").ItemsSource = @(
        [PSCustomObject]@{ Name = "Display Driver (required)";          Tag = "必勾";   Color = $cReq;  Desc = "顯示卡核心驅動（系統強制必選）" }
        [PSCustomObject]@{ Name = "Legacy Control Panel";               Tag = "必勾";   Color = $cReq;  Desc = "傳統 NVIDIA 控制面板（解析度、更新率、G-SYNC 設定必備）" }
        [PSCustomObject]@{ Name = "HD Audio via HDMI";                  Tag = "依需求"; Color = $cOpt;  Desc = "HDMI / DP 數位音效驅動（螢幕有內建喇叭或接擴大機才需勾）" }
        [PSCustomObject]@{ Name = "Microsoft Visual C 2017 Runtimes";   Tag = "建議";   Color = $cRec;  Desc = "VC++ 2017 執行時期元件（驅動與遊戲基礎相依套件）" }
        [PSCustomObject]@{ Name = "PhysX";                              Tag = "建議";   Color = $cRec;  Desc = "物理運算引擎（玩 3D 遊戲建議勾選）" }
        [PSCustomObject]@{ Name = "USB-C Driver";                       Tag = "不勾";   Color = $cSkip; Desc = "顯卡 Type-C 介面驅動（僅少數 RTX 20 系列顯卡需要）" }
        [PSCustomObject]@{ Name = "FrameView SDK";                      Tag = "不勾";   Color = $cSkip; Desc = "幀率與功耗監控套件（評測軟體用，一般玩家免裝）" }
        [PSCustomObject]@{ Name = "Quadro View";                        Tag = "不勾";   Color = $cSkip; Desc = "專業繪圖卡桌面視窗分割工具（僅工作站顯卡適用）" }
        [PSCustomObject]@{ Name = "Virtual Audio";                      Tag = "不勾";   Color = $cSkip; Desc = "虛擬音訊裝置（一般使用者免裝）" }
        [PSCustomObject]@{ Name = "Telemetry";                          Tag = "勿勾";   Color = $cWarn; Desc = "遙測數據回傳元件（收集使用習慣，純淨安裝務必不勾）" }
        [PSCustomObject]@{ Name = "NV Platform Controllers";            Tag = "不勾";   Color = $cSkip; Desc = "筆電平台功耗控制器（桌機免勾）" }
        [PSCustomObject]@{ Name = "NVIDIA DLISR";                       Tag = "不勾";   Color = $cSkip; Desc = "深度學習影像超解析度 SDK 元件（一般遊戲不需要）" }
        [PSCustomObject]@{ Name = "NVIDIA App (及下方所有子項目)";      Tag = "不勾";   Color = $cSkip; Desc = "新版官方遊戲最佳化與錄影套件（包含 Container / ShadowPlay / Backend）" }
    )

    $window.FindName("Grid2").ItemsSource = @(
        [PSCustomObject]@{ Name = "Disable Installer Telemetry & Advertising"; Tag = "必勾";   Color = $cReq;  Desc = "停用安裝程式遙測與廣告畫面" }
        [PSCustomObject]@{ Name = "Unattended Express Installation";           Tag = "建議";   Color = $cRec;  Desc = "無人值守快速安裝（自動完成安裝流程）" }
        [PSCustomObject]@{ Name = "Perform a Clean Installation";              Tag = "建議";   Color = $cRec;  Desc = "執行全新安裝（清除舊版驅動設定檔與快取）" }
        [PSCustomObject]@{ Name = "Add Hardware Support";                      Tag = "不勾";   Color = $cSkip; Desc = "強制寫入硬體相容性 ID（魔改驅動或特殊筆電才用）" }
        [PSCustomObject]@{ Name = "Enable DLSS Indicator";                     Tag = "不勾";   Color = $cSkip; Desc = "遊戲內左下角顯示 DLSS 版本浮水印（除錯測試用）" }
        [PSCustomObject]@{ Name = "Disable Multiplane Overlay (MPO)";          Tag = "依需求"; Color = $cOpt;  Desc = "停用多平面重疊（若雙螢幕看網頁/影片會閃爍黑屏可勾選修復）" }
        [PSCustomObject]@{ Name = "Disable Ansel";                             Tag = "建議";   Color = $cRec;  Desc = "停用 Ansel 遊戲截圖功能（釋放熱鍵並減少背景掛載）" }
        [PSCustomObject]@{ Name = "Show Expert Tweaks";                        Tag = "建議";   Color = $cRec;  Desc = "展開進階專家微調選項（顯示下方第三區設定）" }
    )

    $window.FindName("Grid3").ItemsSource = @(
        [PSCustomObject]@{ Name = "Disable Driver Telemetry";                  Tag = "建議";   Color = $cRec;  Desc = "停用驅動程式背景遙測服務" }
        [PSCustomObject]@{ Name = "Disable NVIDIA Container";                  Tag = "勿勾";   Color = $cWarn; Desc = "⚠️ 勾選會導致「NVIDIA 控制面板」無法開啟，千萬別勾" }
        [PSCustomObject]@{ Name = "Disable NVIDIA HD Audio device sleep timer";Tag = "依需求"; Color = $cOpt;  Desc = "解決 HDMI 螢幕喇叭待機喚醒後前 1~2 秒沒聲音的問題" }
        [PSCustomObject]@{ Name = "Enable Message Signaled Interrupts";        Tag = "建議";   Color = $cRec;  Desc = "啟用 MSI 中斷模式（降低顯卡與 CPU 通訊延遲）" }
        [PSCustomObject]@{ Name = "Disable HDCP";                              Tag = "勿勾";   Color = $cWarn; Desc = "⚠️ 勾選會導致 Netflix、Disney+ 等串流平台無法看高畫質" }
        [PSCustomObject]@{ Name = "Apply NVENC Session Limit Patch";           Tag = "依需求"; Color = $cOpt;  Desc = "解除 NVENC 同時轉碼數量限制（多開直播或媒體伺服器轉碼用）" }
        [PSCustomObject]@{ Name = "Start external application";                Tag = "不勾";   Color = $cSkip; Desc = "安裝完成後自動執行自訂外部程式" }
    )

    $window.FindName("BtnClose").Add_Click({ $window.Close() })
    $window.Add_KeyDown({
        if ($_.Key -eq [System.Windows.Input.Key]::Escape) { $window.Close() }
    })

    [void]$window.ShowDialog()
}