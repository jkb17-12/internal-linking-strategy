<#
  build-xlsx.ps1  —  Turns output/recommendations.md into the standard Excel file.
  Same output for every client. Requires Microsoft Excel installed (Windows).

  Tabs produced:
    1. Sheet-Ready          one row per blog (verbatim links, mirrors the Blog Links tab)
    2. Detailed             one row per verbatim link
    3. Suggested-Additions  one row per SUGGEST: block (new copy to add: sentence + placement)

  This tool is client-agnostic. Point it at ONE client's recommendations file per run — the
  file you feed is the source of truth. The convention is per-client filenames:
    output/<client>-recommendations.md  ->  output/<client>-internal-links.xlsx

  Usage (from anywhere):
    powershell -ExecutionPolicy Bypass -File tools\build-xlsx.ps1 -Client "big-smile-dental"
    powershell -ExecutionPolicy Bypass -File tools\build-xlsx.ps1 -In path\to\<client>-recommendations.md

  -Client slug that names BOTH the input and output by convention (recommended way to run).
  -In     explicit path to a <client>-recommendations.md (overrides the -Client default).
  -Out    explicit path to the .xlsx to write (defaults to <client>-internal-links.xlsx).
#>
param(
  [string]$In     = '',
  [string]$Out    = '',
  [string]$Client = ''
)
$ErrorActionPreference = 'Stop'

# Resolve the input file. Prefer an explicit -In; otherwise derive it from -Client.
# There is deliberately NO fixed single-site default — you must say which client.
if (-not $In) {
  if ($Client) { $In = "$PSScriptRoot\..\output\$Client-recommendations.md" }
  else { throw "Provide -Client <slug> (uses output\<slug>-recommendations.md) or -In <path to a recommendations.md>." }
}

if (-not $Out) {
  $base = [System.IO.Path]::GetFileNameWithoutExtension($In) -replace '-recommendations$',''
  $name = if ($Client) { "$Client-internal-links.xlsx" } else { "$base-internal-links.xlsx" }
  $Out = Join-Path (Split-Path $In -Parent) $name
}
if (-not (Test-Path $In)) { throw "Cannot find recommendations file: $In" }

# --- Parse recommendations.md ---
#   BLOG: <url>
#   Anchor: <verbatim>  Target: <url>                (verbatim links)
#   SUGGEST: <anchor>  Target: <url>                 (suggested new copy)
#     Sentence: <full sentence to add>
#     Placement: <where to insert it>
$lines = (Get-Content -Raw -Encoding UTF8 $In) -split "`r?`n"
$blogs = New-Object System.Collections.ArrayList
$cur = $null
$curSug = $null
foreach ($ln in $lines) {
  if ($ln -match '^BLOG:\s*(\S+)') {
    if ($cur -and $curSug) { [void]$cur.Suggests.Add($curSug) }; $curSug = $null
    if ($cur) { [void]$blogs.Add($cur) }
    $cur = [ordered]@{ Url = $matches[1]; Links = (New-Object System.Collections.ArrayList); Suggests = (New-Object System.Collections.ArrayList) }
  }
  elseif ($ln -match '^SUGGEST:\s*(.+?)\s+Target:\s*(\S+)\s*$') {
    if ($cur -and $curSug) { [void]$cur.Suggests.Add($curSug) }
    $curSug = [pscustomobject]@{ Anchor = $matches[1].Trim(); Target = $matches[2].Trim(); Sentence = ''; Placement = '' }
  }
  elseif ($ln -match '^\s*Sentence:\s*(.+?)\s*$')  { if ($curSug) { $curSug.Sentence  = $matches[1].Trim() } }
  elseif ($ln -match '^\s*Placement:\s*(.+?)\s*$') { if ($curSug) { $curSug.Placement = $matches[1].Trim() } }
  elseif ($ln -match '^Anchor:\s*(.+?)\s+Target:\s*(\S+)\s*$') {
    if ($cur -and $curSug) { [void]$cur.Suggests.Add($curSug); $curSug = $null }
    if ($cur) { [void]$cur.Links.Add([pscustomobject]@{ Anchor = $matches[1].Trim(); Target = $matches[2].Trim() }) }
  }
}
if ($cur -and $curSug) { [void]$cur.Suggests.Add($curSug) }
if ($cur) { [void]$blogs.Add($cur) }
if ($blogs.Count -eq 0) { throw "No 'BLOG:' entries found in $In" }

function Get-Type($u) {
  if ($u -match '/(our-services|dental-services|services|service)/') { return 'Service' }
  if ($u -match '/(about|about-us|our-doctors|our-team|meet-the-team|contact|contact-us|location|locations|payment|payment-options|financing|gallery|smile-gallery|book|appointment|our-office)') { return 'Key Page' }
  return 'Blog'
}
$nl = [char]10

# --- Sheet 1 data: one row per blog (verbatim links only) ---
$sr = New-Object 'object[,]' $blogs.Count,3
for ($i=0; $i -lt $blogs.Count; $i++) {
  $b = $blogs[$i]; $pairs = @()
  foreach ($lk in $b.Links) { $pairs += ("Anchor: {0}  Target: {1}" -f $lk.Anchor, $lk.Target) }
  $sr[$i,0] = $b.Url; $sr[$i,1] = ($pairs -join $nl); $sr[$i,2] = ''
}

# --- Sheet 2 data: one row per verbatim link ---
$det = New-Object System.Collections.ArrayList
foreach ($b in $blogs) { foreach ($lk in $b.Links) {
  [void]$det.Add([pscustomobject]@{ Blog=$b.Url; Anchor=$lk.Anchor; Target=$lk.Target; Type=(Get-Type $lk.Target) })
}}
$dArr = New-Object 'object[,]' ([Math]::Max($det.Count,1)),4
for ($i=0; $i -lt $det.Count; $i++) { $dArr[$i,0]=$det[$i].Blog; $dArr[$i,1]=$det[$i].Anchor; $dArr[$i,2]=$det[$i].Target; $dArr[$i,3]=$det[$i].Type }

# --- Sheet 3 data: one row per suggested addition ---
$sug = New-Object System.Collections.ArrayList
foreach ($b in $blogs) { foreach ($s in $b.Suggests) {
  [void]$sug.Add([pscustomobject]@{ Blog=$b.Url; Anchor=$s.Anchor; Sentence=$s.Sentence; Placement=$s.Placement; Target=$s.Target; Type=(Get-Type $s.Target) })
}}
$sArr = New-Object 'object[,]' ([Math]::Max($sug.Count,1)),6
for ($i=0; $i -lt $sug.Count; $i++) { $sArr[$i,0]=$sug[$i].Blog; $sArr[$i,1]=$sug[$i].Anchor; $sArr[$i,2]=$sug[$i].Sentence; $sArr[$i,3]=$sug[$i].Placement; $sArr[$i,4]=$sug[$i].Target; $sArr[$i,5]=$sug[$i].Type }

# --- Build the workbook via Excel ---
$xl = New-Object -ComObject Excel.Application
$xl.Visible = $false; $xl.DisplayAlerts = $false
$wb = $xl.Workbooks.Add()
while ($wb.Worksheets.Count -gt 1) { $wb.Worksheets.Item($wb.Worksheets.Count).Delete() }

$ws1 = $wb.Worksheets.Item(1); $ws1.Name = 'Sheet-Ready'
$ws1.Cells.Item(1,1) = 'Blog Links'
$ws1.Cells.Item(1,2) = 'Internal Link -> Anchor Texts'
$ws1.Cells.Item(1,3) = 'Status'
$ws1.Range($ws1.Cells.Item(2,1), $ws1.Cells.Item(1+$blogs.Count,3)).Value2 = $sr
$ws1.Range('A1:C1').Font.Bold = $true
$ws1.Columns.Item(1).ColumnWidth = 55
$ws1.Columns.Item(2).ColumnWidth = 80
$ws1.Columns.Item(3).ColumnWidth = 10
$ws1.Columns.Item(2).WrapText = $true
$ws1.Rows.AutoFit() | Out-Null
$xl.ActiveWindow.SplitRow = 1; $xl.ActiveWindow.FreezePanes = $true

$ws2 = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $ws1); $ws2.Name = 'Detailed'
$ws2.Cells.Item(1,1) = 'Blog URL'
$ws2.Cells.Item(1,2) = 'Anchor Text'
$ws2.Cells.Item(1,3) = 'Target URL'
$ws2.Cells.Item(1,4) = 'Target Type'
if ($det.Count -gt 0) { $ws2.Range($ws2.Cells.Item(2,1), $ws2.Cells.Item(1+$det.Count,4)).Value2 = $dArr }
$ws2.Range('A1:D1').Font.Bold = $true
$ws2.Columns.Item(1).ColumnWidth = 55
$ws2.Columns.Item(2).ColumnWidth = 40
$ws2.Columns.Item(3).ColumnWidth = 55
$ws2.Columns.Item(4).ColumnWidth = 12

$ws3 = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $ws2); $ws3.Name = 'Suggested-Additions'
$ws3.Cells.Item(1,1) = 'Blog URL'
$ws3.Cells.Item(1,2) = 'Suggested Anchor'
$ws3.Cells.Item(1,3) = 'Sentence To Add'
$ws3.Cells.Item(1,4) = 'Placement'
$ws3.Cells.Item(1,5) = 'Target URL'
$ws3.Cells.Item(1,6) = 'Target Type'
if ($sug.Count -gt 0) { $ws3.Range($ws3.Cells.Item(2,1), $ws3.Cells.Item(1+$sug.Count,6)).Value2 = $sArr }
$ws3.Range('A1:F1').Font.Bold = $true
$ws3.Columns.Item(1).ColumnWidth = 50
$ws3.Columns.Item(2).ColumnWidth = 26
$ws3.Columns.Item(3).ColumnWidth = 70
$ws3.Columns.Item(4).ColumnWidth = 50
$ws3.Columns.Item(5).ColumnWidth = 50
$ws3.Columns.Item(6).ColumnWidth = 12
$ws3.Columns.Item(3).WrapText = $true
$ws3.Columns.Item(4).WrapText = $true
$ws3.Rows.AutoFit() | Out-Null

$ws1.Activate()
$wb.SaveAs($Out, 51)   # 51 = .xlsx
$wb.Close($false); $xl.Quit()
foreach ($o in @($ws1,$ws2,$ws3,$wb,$xl)) { [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($o) }
[GC]::Collect()

Write-Output ("OK - {0} blogs, {1} verbatim links, {2} suggested -> {3}" -f $blogs.Count, $det.Count, $sug.Count, $Out)
