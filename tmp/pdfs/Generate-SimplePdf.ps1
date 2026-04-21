param(
    [string]$InputPath = "C:\Users\ASUS\Documents\Codex\pingateAPI\tmp\pdfs\pingate-study-guide.md",
    [string]$OutputPath = "C:\Users\ASUS\Documents\Codex\pingateAPI\output\pdf\PinGate-Identity-Setup-Guide.pdf"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Escape-PdfText {
    param([string]$Text)

    return $Text.Replace("\", "\\").Replace("(", "\(").Replace(")", "\)")
}

function Wrap-Text {
    param(
        [string]$Text,
        [int]$MaxChars
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return [string[]]@("")
    }

    $words = $Text -split '\s+'
    $lines = New-Object System.Collections.Generic.List[string]
    $current = ""

    foreach ($word in $words) {
        if ([string]::IsNullOrWhiteSpace($current)) {
            $current = $word
            continue
        }

        if (($current.Length + 1 + $word.Length) -le $MaxChars) {
            $current = "$current $word"
        }
        else {
            $lines.Add($current)
            $current = $word
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($current)) {
        $lines.Add($current)
    }

    return [string[]]$lines.ToArray()
}

function Add-RenderedLines {
    param(
        [System.Collections.Generic.List[object]]$Pages,
        [ref]$CurrentPage,
        [ref]$CurrentY,
        [string]$Font,
        [double]$Size,
        [double]$LineHeight,
        [double]$X,
        [string[]]$Lines,
        [double]$AfterGap = 0
    )

    foreach ($line in $Lines) {
        if ($CurrentY.Value -lt 48) {
            $Pages.Add((New-Object System.Collections.Generic.List[object]))
            $CurrentPage.Value = $Pages[$Pages.Count - 1]
            $CurrentY.Value = 756
        }

        $CurrentPage.Value.Add([pscustomobject]@{
            Font = $Font
            Size = $Size
            X    = $X
            Y    = [math]::Round($CurrentY.Value, 2)
            Text = $line
        })

        $CurrentY.Value -= $LineHeight
    }

    $CurrentY.Value -= $AfterGap
}

$inputDirectory = Split-Path -Parent $InputPath
$outputDirectory = Split-Path -Parent $OutputPath

if (-not (Test-Path -LiteralPath $inputDirectory)) {
    throw "Input directory not found: $inputDirectory"
}

if (-not (Test-Path -LiteralPath $InputPath)) {
    throw "Input file not found: $InputPath"
}

if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$sourceLines = Get-Content -LiteralPath $InputPath
$pages = New-Object System.Collections.Generic.List[object]
$firstPage = New-Object System.Collections.Generic.List[object]
$pages.Add($firstPage)
$currentPage = $firstPage
$currentY = 756.0

foreach ($rawLine in $sourceLines) {
    $line = $rawLine.TrimEnd()

    if ($line.Length -eq 0) {
        $currentY -= 8
        continue
    }

    if ($line.StartsWith("# ")) {
        $wrapped = @(Wrap-Text -Text $line.Substring(2) -MaxChars 40)
        Add-RenderedLines -Pages $pages -CurrentPage ([ref]$currentPage) -CurrentY ([ref]$currentY) -Font "F2" -Size 18 -LineHeight 24 -X 54 -Lines $wrapped -AfterGap 4
        continue
    }

    if ($line.StartsWith("## ")) {
        $wrapped = @(Wrap-Text -Text $line.Substring(3) -MaxChars 55)
        Add-RenderedLines -Pages $pages -CurrentPage ([ref]$currentPage) -CurrentY ([ref]$currentY) -Font "F2" -Size 14 -LineHeight 18 -X 54 -Lines $wrapped -AfterGap 2
        continue
    }

    if ($line.StartsWith("### ")) {
        $wrapped = @(Wrap-Text -Text $line.Substring(4) -MaxChars 70)
        Add-RenderedLines -Pages $pages -CurrentPage ([ref]$currentPage) -CurrentY ([ref]$currentY) -Font "F2" -Size 12 -LineHeight 15 -X 54 -Lines $wrapped
        continue
    }

    if ($line.StartsWith("    ")) {
        $wrapped = @(Wrap-Text -Text $line.TrimStart() -MaxChars 74)
        Add-RenderedLines -Pages $pages -CurrentPage ([ref]$currentPage) -CurrentY ([ref]$currentY) -Font "F3" -Size 9.5 -LineHeight 12 -X 72 -Lines $wrapped
        continue
    }

    if ($line.StartsWith("- ")) {
        $wrapped = @(Wrap-Text -Text $line.Substring(2) -MaxChars 80)
        if ($wrapped.Count -gt 0) {
            $bulletLines = New-Object System.Collections.Generic.List[string]
            $bulletLines.Add("- $($wrapped[0])")
            for ($index = 1; $index -lt $wrapped.Count; $index++) {
                $bulletLines.Add("  $($wrapped[$index])")
            }

            Add-RenderedLines -Pages $pages -CurrentPage ([ref]$currentPage) -CurrentY ([ref]$currentY) -Font "F1" -Size 10.5 -LineHeight 13 -X 54 -Lines $bulletLines
        }

        continue
    }

    if ($line -match '^\d+\.\s') {
        $prefix = $line.Substring(0, $line.IndexOf(' ') + 1)
        $body = $line.Substring($prefix.Length)
        $wrapped = @(Wrap-Text -Text $body -MaxChars 78)

        if ($wrapped.Count -gt 0) {
            $numberedLines = New-Object System.Collections.Generic.List[string]
            $numberedLines.Add("$prefix$($wrapped[0])")
            for ($index = 1; $index -lt $wrapped.Count; $index++) {
                $numberedLines.Add((" " * $prefix.Length) + $wrapped[$index])
            }

            Add-RenderedLines -Pages $pages -CurrentPage ([ref]$currentPage) -CurrentY ([ref]$currentY) -Font "F1" -Size 10.5 -LineHeight 13 -X 54 -Lines $numberedLines
        }

        continue
    }

    $paragraphLines = @(Wrap-Text -Text $line -MaxChars 88)
    Add-RenderedLines -Pages $pages -CurrentPage ([ref]$currentPage) -CurrentY ([ref]$currentY) -Font "F1" -Size 10.5 -LineHeight 13 -X 54 -Lines $paragraphLines
}

$pageCount = $pages.Count

for ($pageIndex = 0; $pageIndex -lt $pageCount; $pageIndex++) {
    $pages[$pageIndex].Add([pscustomobject]@{
        Font = "F1"
        Size = 9
        X    = 280
        Y    = 28
        Text = "Page $($pageIndex + 1) of $pageCount"
    })
}

$objects = New-Object System.Collections.Generic.List[string]
$objects.Add("<< /Type /Catalog /Pages 2 0 R >>")

$pageObjectNumbers = @()
$contentObjectNumbers = @()

for ($pageIndex = 0; $pageIndex -lt $pageCount; $pageIndex++) {
    $pageObjectNumbers += (6 + ($pageIndex * 2))
    $contentObjectNumbers += (7 + ($pageIndex * 2))
}

$kids = ($pageObjectNumbers | ForEach-Object { "$_ 0 R" }) -join " "
$objects.Add("<< /Type /Pages /Count $pageCount /Kids [ $kids ] >>")
$objects.Add("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")
$objects.Add("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>")
$objects.Add("<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>")

for ($pageIndex = 0; $pageIndex -lt $pageCount; $pageIndex++) {
    $pageObjectNumber = $pageObjectNumbers[$pageIndex]
    $contentObjectNumber = $contentObjectNumbers[$pageIndex]

    $pageObject = "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 3 0 R /F2 4 0 R /F3 5 0 R >> >> /Contents $contentObjectNumber 0 R >>"
    $objects.Add($pageObject)

    $commands = New-Object System.Collections.Generic.List[string]
    foreach ($item in $pages[$pageIndex]) {
        $escapedText = Escape-PdfText -Text $item.Text
        $commands.Add("BT")
        $commands.Add("/$($item.Font) $($item.Size) Tf")
        $commands.Add("1 0 0 1 $($item.X) $($item.Y) Tm")
        $commands.Add("($escapedText) Tj")
        $commands.Add("ET")
    }

    $streamContent = ($commands -join "`n") + "`n"
    $length = [System.Text.Encoding]::ASCII.GetByteCount($streamContent)
    $contentObject = "<< /Length $length >>`nstream`n$streamContent" + "endstream"
    $objects.Add($contentObject)
}

$builder = New-Object System.Text.StringBuilder
[void]$builder.Append("%PDF-1.4`n")

$offsets = New-Object System.Collections.Generic.List[int]
$ascii = [System.Text.Encoding]::ASCII

for ($index = 0; $index -lt $objects.Count; $index++) {
    $offsets.Add($ascii.GetByteCount($builder.ToString()))
    [void]$builder.AppendFormat("{0} 0 obj`n{1}`nendobj`n", $index + 1, $objects[$index])
}

$xrefStart = $ascii.GetByteCount($builder.ToString())
[void]$builder.Append("xref`n")
[void]$builder.AppendFormat("0 {0}`n", $objects.Count + 1)
[void]$builder.Append("0000000000 65535 f `n")

foreach ($offset in $offsets) {
    [void]$builder.AppendFormat("{0:0000000000} 00000 n `n", $offset)
}

[void]$builder.Append("trailer`n")
[void]$builder.AppendFormat("<< /Size {0} /Root 1 0 R >>`n", $objects.Count + 1)
[void]$builder.Append("startxref`n")
[void]$builder.AppendFormat("{0}`n", $xrefStart)
[void]$builder.Append("%%EOF")

[System.IO.File]::WriteAllText($OutputPath, $builder.ToString(), $ascii)
Write-Output "PDF_CREATED:$OutputPath"
