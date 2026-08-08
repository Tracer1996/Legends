<#
.SYNOPSIS
  Scans the OctoWoW database's Misc/Junk item list and flags which ones are
  actual "toys" (items whose tooltip has the Toy Box "Use:" line), so they
  can be fed into a new Toys collection for LeafVillageAchievements.

.DESCRIPTION
  Step 1: Fetches https://octowow.st/db/?items=15.0 (Misc > Junk) and pulls
          the embedded `data: [...]` item array out of the page source --
          same list format already used for mounts (15.4) and companions (15.2).
  Step 2: For every item ID found, fetches https://octowow.st/db/?item=<id>
          and checks the raw page text for "Adds a toy to the player's toy
          collection." -- confirmed present on real toys (Croak Cannon, Toy
          Train Set) and absent on plain junk (Guild Charter).
  Step 3: Writes every checked item (toy or not) to a progress CSV as it
          goes, so the run is resumable if interrupted, then writes the
          toy-only subset to a final CSV/JSON.

.PARAMETER Limit
  Optional cap on how many items to check (for a quick test run).

.PARAMETER DelayMs
  Delay between individual item-page requests, in milliseconds. Keep this
  reasonable -- this script hits the site once per item, and the junk list
  can run into the hundreds.
#>

param(
    [string]$ListUrl = "https://octowow.st/db/?items=15.0",
    [string]$ItemUrlTemplate = "https://octowow.st/db/?item={0}",
    [string]$OutDir = "$PSScriptRoot\toy-scan",
    [int]$Limit = 0,
    [int]$DelayMs = 300
)

$ErrorActionPreference = "Stop"
$ToySignature = "Adds a toy to the player's toy collection"

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir | Out-Null
}
$ProgressCsv = Join-Path $OutDir "progress.csv"
$ToysCsv     = Join-Path $OutDir "toys_found.csv"
$ToysJson    = Join-Path $OutDir "toys_found.json"

$Headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
}

function Get-ItemListFromPage {
    param([string]$Url)

    Write-Host "Fetching item list: $Url"
    $resp = Invoke-WebRequest -Uri $Url -Headers $Headers -UseBasicParsing
    $html = $resp.Content

    # The list page embeds a flat (non-nested) array of item objects as
    # inline JS, e.g. `data: [{name: '...', id: 1234}, {...}]`. Each object
    # has no nested braces, so matching balanced {...} blocks is enough --
    # no need for a real JS/JSON parser.
    $objectMatches = [regex]::Matches($html, '\{(?:[^{}])*\}')

    $items = foreach ($m in $objectMatches) {
        $block = $m.Value
        if ($block -notmatch 'id:\s*(\d+)') { continue }
        $id = [int]$Matches[1]

        $name = $null
        if ($block -match "name:\s*'((?:[^'\\]|\\.)*)'") {
            $name = $Matches[1] -replace '\\(.)', '$1'
            # Strip the site's own leading sort/tier digit prefix on names
            # (e.g. "1Atiesh..." / "3Advanced Gemology I") -- not part of
            # the real item name.
            $name = $name -replace '^\d+', ''
        }

        $desc = $null
        if ($block -match "description:\s*'((?:[^'\\]|\\.)*)'") {
            $desc = $Matches[1] -replace '\\(.)', '$1'
        }

        if ($name) {
            [PSCustomObject]@{
                Id          = $id
                Name        = $name
                Description = $desc
            }
        }
    }

    # Same id can appear more than once across pagination artifacts in the
    # source; de-dupe defensively.
    $items | Sort-Object Id -Unique
}

function Test-IsToyItem {
    param([int]$Id)

    $url = [string]::Format($ItemUrlTemplate, $Id)
    try {
        $resp = Invoke-WebRequest -Uri $url -Headers $Headers -UseBasicParsing
        return $resp.Content -match [regex]::Escape($ToySignature)
    } catch {
        Write-Warning "Failed to fetch item $Id ($url): $_"
        return $null
    }
}

$allItems = Get-ItemListFromPage -Url $ListUrl
Write-Host "Found $($allItems.Count) junk items in the list."

if ($Limit -gt 0) {
    $allItems = $allItems | Select-Object -First $Limit
    Write-Host "Limiting to first $Limit items for this run."
}

$already = @{}
if (Test-Path $ProgressCsv) {
    Import-Csv $ProgressCsv | ForEach-Object { $already[[int]$_.Id] = $_ }
    Write-Host "Resuming: $($already.Count) items already checked in a previous run."
}

if (-not (Test-Path $ProgressCsv)) {
    "Id,Name,Description,IsToy,CheckedAt" | Out-File -FilePath $ProgressCsv -Encoding UTF8
}

$total = $allItems.Count
$i = 0
foreach ($item in $allItems) {
    $i++
    if ($already.ContainsKey($item.Id)) { continue }

    Write-Progress -Activity "Checking items for toy signature" -Status "$($item.Name) ($($item.Id))" -PercentComplete (($i / $total) * 100)

    $isToy = Test-IsToyItem -Id $item.Id

    $descEscaped = if ($item.Description) { $item.Description -replace '"', '""' } else { "" }
    $nameEscaped = $item.Name -replace '"', '""'
    $row = '"{0}","{1}","{2}","{3}","{4}"' -f $item.Id, $nameEscaped, $descEscaped, $isToy, (Get-Date -Format "s")
    Add-Content -Path $ProgressCsv -Value $row

    Start-Sleep -Milliseconds $DelayMs
}

Write-Progress -Activity "Checking items for toy signature" -Completed

$results = Import-Csv $ProgressCsv
$toys = $results | Where-Object { $_.IsToy -eq "True" }

$toys | Export-Csv -Path $ToysCsv -NoTypeInformation -Encoding UTF8
$toys | ConvertTo-Json -Depth 3 | Out-File -FilePath $ToysJson -Encoding UTF8

Write-Host ""
Write-Host "Done. Checked $($results.Count) items, found $($toys.Count) toys."
Write-Host "Full progress log: $ProgressCsv"
Write-Host "Toys only (CSV):   $ToysCsv"
Write-Host "Toys only (JSON):  $ToysJson"
