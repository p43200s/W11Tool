param([string]$RootDir)
$ErrorActionPreference = "Stop"

$outputFile = "code_dump.txt"
$outputPath = Join-Path $RootDir $outputFile

$tee  = "$([char]0x251C)$([char]0x2500)$([char]0x2500) "
$last = "$([char]0x2514)$([char]0x2500)$([char]0x2500) "
$pipe = "$([char]0x2502)   "

$targetFiles = Get-ChildItem -Path $RootDir -Recurse -File -Include *.bat,*.ps1,*.psm1,*.psd1,*.md |
Where-Object {
    $_.Name -ne $outputFile -and $_.Name -notlike "W11Tool_*.bat"
} | Sort-Object FullName

function Get-TreeLines {
    param([string]$CurrentPath, [string]$Prefix = "")

    $items = Get-ChildItem -Path $CurrentPath | Where-Object {
        $currItem = $_
        if ($currItem.PSIsContainer) {
            $dirPrefix = $currItem.FullName + "\"
            return ($targetFiles | Where-Object { $_.FullName.StartsWith($dirPrefix) }).Count -gt 0
        } else {
            return $targetFiles.FullName -contains $currItem.FullName
        }
    } | Sort-Object { -not $_.PSIsContainer }, Name

    for ($i = 0; $i -lt $items.Count; $i++) {
        $item      = $items[$i]
        $isLast    = ($i -eq ($items.Count - 1))
        $connector = if ($isLast) { $last } else { $tee }

        "$Prefix$connector$($item.Name)"

        if ($item.PSIsContainer) {
            $nextPrefix = $Prefix + $(if ($isLast) { "    " } else { $pipe })
            Get-TreeLines -CurrentPath $item.FullName -Prefix $nextPrefix
        }
    }
}

$outputLines = @(
    "=== PROJECT DIRECTORY TREE ==="
    (Split-Path $RootDir -Leaf)
    Get-TreeLines -CurrentPath $RootDir
    ""
    "=== SOURCE CODE DUMP ==="
    foreach ($file in $targetFiles) {
        $relPath = $file.FullName.Substring($RootDir.Length + 1)
        "=== $relPath ==="
        Get-Content $file.FullName -Raw -Encoding UTF8
        ""
    }
)

[System.IO.File]::WriteAllLines($outputPath, $outputLines, (New-Object System.Text.UTF8Encoding $false))
Write-Host "`n[OK] 已將目錄樹與原始碼匯出至 $outputFile" -ForegroundColor Green