param(
  [string]$ConfigPath = "$PSScriptRoot\LeafVE.DiscordBridge.config.json"
)

$ErrorActionPreference = "Stop"

function Write-BridgeLog {
  param([string]$Message)
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Write-Host "[$timestamp] $Message"
}

function Load-BridgeConfig {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Config file not found: $Path"
  }

  $raw = Get-Content -LiteralPath $Path -Raw
  $config = $raw | ConvertFrom-Json
  if (-not $config.webhookUrl) {
    throw "Missing webhookUrl in $Path"
  }
  if (-not $config.wowLogPath) {
    throw "Missing wowLogPath in $Path"
  }
  return $config
}

function Remove-WowMarkup {
  param([string]$Text)

  if ([string]::IsNullOrEmpty($Text)) {
    return ""
  }

  $clean = $Text
  $clean = [regex]::Replace($clean, '\|c[0-9A-Fa-f]{8}', '')
  $clean = $clean -replace '\|r', ''
  $clean = [regex]::Replace($clean, '\|H[^|]+\|h', '')
  $clean = $clean -replace '\|h', ''
  return $clean
}

function Test-GuildBadgeAnnouncementLine {
  param(
    [string]$RawLine,
    [bool]$GuildOnly
  )

  if ([string]::IsNullOrWhiteSpace($RawLine)) {
    return $false
  }

  $clean = Remove-WowMarkup $RawLine
  if ([string]::IsNullOrWhiteSpace($clean)) {
    return $false
  }

  if ($clean -like '*has earned the achievement*') {
    return $false
  }

  $looksLikeBadge = $clean -match 'earned \[[^\]]+\] for .+'
  if (-not $looksLikeBadge) {
    return $false
  }

  if (-not $GuildOnly) {
    return $true
  }

  return $clean -match '\[(Guild|G)\]' -or $clean -match 'CHAT_MSG_GUILD'
}

function Format-DiscordContent {
  param([string]$RawLine)

  $clean = Remove-WowMarkup $RawLine
  $clean = $clean -replace '\s+', ' '
  return $clean.Trim()
}

function Send-DiscordMessage {
  param(
    [string]$WebhookUrl,
    [string]$BridgeName,
    [string]$Content
  )

  if ([string]::IsNullOrWhiteSpace($Content)) {
    return
  }

  $body = @{
    username = $BridgeName
    content = $Content
    allowed_mentions = @{
      parse = @()
    }
  } | ConvertTo-Json -Depth 5

  Invoke-RestMethod -Method Post -Uri $WebhookUrl -ContentType 'application/json' -Body $body | Out-Null
}

function Resolve-ChatLogPath {
  param([string]$ConfiguredPath)

  if (Test-Path -LiteralPath $ConfiguredPath) {
    return $ConfiguredPath
  }

  $logDirectory = Split-Path -Path $ConfiguredPath -Parent
  if (-not (Test-Path -LiteralPath $logDirectory)) {
    return $ConfiguredPath
  }

  $latest = Get-ChildItem -LiteralPath $logDirectory -Filter 'WoWChatLog*.txt' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

  if ($latest) {
    return $latest.FullName
  }

  return $ConfiguredPath
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$config = Load-BridgeConfig -Path $ConfigPath
$bridgeName = if ($config.bridgeName) { [string]$config.bridgeName } else { 'LeafVE Badges' }
$pollIntervalSeconds = [int]($config.pollIntervalSeconds | ForEach-Object { $_ })
if ($pollIntervalSeconds -lt 1) { $pollIntervalSeconds = 2 }
$guildOnly = [bool]$config.guildOnly
$debug = [bool]$config.debug

Write-BridgeLog "LeafVE Discord badge bridge starting."
Write-BridgeLog "Guild-only mode: $guildOnly"

$lastPostedContent = ""
$lastPostedAt = Get-Date '2000-01-01'

while ($true) {
  $logPath = Resolve-ChatLogPath -ConfiguredPath ([string]$config.wowLogPath)
  while (-not (Test-Path -LiteralPath $logPath)) {
    Write-BridgeLog "Waiting for chat log: $logPath"
    Start-Sleep -Seconds $pollIntervalSeconds
    $logPath = Resolve-ChatLogPath -ConfiguredPath ([string]$config.wowLogPath)
  }

  Write-BridgeLog "Watching $logPath"

  try {
    Get-Content -LiteralPath $logPath -Wait -Tail 0 | ForEach-Object {
      $line = [string]$_
      if ($debug) {
        Write-BridgeLog "Log line: $line"
      }

      if (-not (Test-GuildBadgeAnnouncementLine -RawLine $line -GuildOnly $guildOnly)) {
        return
      }

      $content = Format-DiscordContent -RawLine $line
      if ([string]::IsNullOrWhiteSpace($content)) {
        return
      }

      $now = Get-Date
      $duplicate = $content -eq $lastPostedContent -and (($now - $lastPostedAt).TotalSeconds -lt 10)
      if ($duplicate) {
        return
      }

      Send-DiscordMessage -WebhookUrl ([string]$config.webhookUrl) -BridgeName $bridgeName -Content $content
      $lastPostedContent = $content
      $lastPostedAt = $now
      Write-BridgeLog "Posted badge announcement to Discord."
    }
  } catch {
    Write-BridgeLog "Watcher error: $($_.Exception.Message)"
    Start-Sleep -Seconds $pollIntervalSeconds
  }
}
