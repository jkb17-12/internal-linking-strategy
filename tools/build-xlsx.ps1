<#
  build-xlsx.ps1  —  Turns output/recommendations.md into the standard two-tab Excel file.
  Same output for every client. Requires Microsoft Excel installed (Windows).

  Usage (from anywhere):
    powershell -ExecutionPolicy Bypass -File tools\build-xlsx.ps1
    powershell -ExecutionPolicy Bypass -File tools\build-xlsx.ps1 -Client "big-smile-dental"

  -In     path to recommendations.md   (default: ..\output\recommendations.md)
  -Out    path to the .xlsx to write    (default: ..\output\internal-links.xlsx,
                                          or ..\output\<Client>-internal-links.xlsx)
  -Client optional slug used to name the output file
#>
param(
  [string]$In     = "$PSScriptRoot\..\output\recommendations.md",
  [string]$Out    = '',
  [string]$Client = ''
)
$ErrorActionPreference = 'Stop'

if (-not $Out) {
  $dir = Join-Path (Split-Path $In -Parent) ''
  $name = if ($Client) { "$Client-internal-links.xlsx" } else { 'internal-links.xlsx' }
  $Out = Join-Path (Split-Path $In -Parent) $name
}
if (-not (Test-Path $In)) { throw "Cannot find recommendations file: $In" }

# --- Parse recommendations.md (canonical format: 'BLOG:' lines and 'Anchor: X  Target: Y' lines) ---
$lines = (Get-Content -Raw -Encoding UTF8 $In) -split "`r?`n"
$blogs = New-Object System.Collections.ArrayList
$cur = $null
foreach ($ln in $lines) {
  if ($ln -match '^BLOG:\s*(\S+)') {
    if ($cur) { [void]$blogs.Add($cur) }
    $cur = [ordered]@{ Url = $matches[1]; Links = (New-Object System.Collections.ArrayList) }
  }
  elseif ($ln -match '^Anchor:\s*(.+?)\s+Target:\s*(\S+)\s*$') {
    if ($cur) { [void]$cur.Links.Add([pscustomobject]@{ Anchor = $matches[1].Trim(); Target = $matches[2].Trim() }) }
  }
}
if ($cur) { [void]$blogs.Add($cur) }
if ($blogs.Count -eq 0) { throw "No 'BLOG:' entries found in $In" }

function Get-Type($u) {
  if ($u -match '/(our-services|services|service)/') { return 'Service' }
  if ($u -match '/(about|about-us|our-doctors|our-team|meet-the-team|contact|contact-us|location|locations|payment|payment-options|financing|gallery|smile-gallery|book|appointment|our-office)') { return 'Key Page' }
  return 'Blog'
}
$nl = [char]10

# --- Sheet 1: one row per blog (matches the Blog Links tab) ---
$sr = New-Object 'object[,]' $blogs.Count,3
for ($i=0; $i -lt $blogs.Count; $i++) {
  $b = $blogs[$i]; $pairs = @()
  foreach ($lk in $b.Links) { $pairs += ("Anchor: {0}  Target: {1}" -f $lk.Anchor, $lk.Target) }
  $sr[$i,0] = $b.Url; $sr[$i,1] = ($pairs -join $nl); $sr[$i,2] = ''
}

# --- Sheet 2: one row per link ---
$det = New-Object System.Collections.ArrayList
foreach ($b in $blogs) { foreach ($lk in $b.Links) {
  [void]$det.Add([pscustomobject]@{ Blog=$b.Url; Anchor=$lk.Anchor; Target=$lk.Target; Type=(Get-Type $lk.Target) })
}}
$dArr = New-Object 'object[,]' $det.Count,4
for ($i=0; $i -lt $det.Count; $i++) { $dArr[$i,0]=$det[$i].Blog; $dArr[$i,1]=$det[$i].Anchor; $dArr[$i,2]=$det[$i].Target; $dArr[$i,3]=$det[$i].Type }

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
$ws2.Range($ws2.Cells.Item(2,1), $ws2.Cells.Item(1+$det.Count,4)).Value2 = $dArr
$ws2.Range('A1:D1').Font.Bold = $true
$ws2.Columns.Item(1).ColumnWidth = 55
$ws2.Columns.Item(2).ColumnWidth = 40
$ws2.Columns.Item(3).ColumnWidth = 55
$ws2.Columns.Item(4).ColumnWidth = 12

$ws1.Activate()
$wb.SaveAs($Out, 51)   # 51 = .xlsx
$wb.Close($false); $xl.Quit()
foreach ($o in @($ws1,$ws2,$wb,$xl)) { [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($o) }
[GC]::Collect()

Write-Output ("OK - {0} blogs, {1} links -> {2}" -f $blogs.Count, $det.Count, $Out)
