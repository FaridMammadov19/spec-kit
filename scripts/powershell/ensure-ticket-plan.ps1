#!/usr/bin/env pwsh
[CmdletBinding()]
param(
  [switch]$Json,
  [switch]$Help,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Args
)

$ErrorActionPreference = 'Stop'

if ($Help) {
  Write-Host "Usage: ./ensure-ticket-plan.ps1 [-Json] <TICKET-ID>"
  exit 0
}

if (-not $Args -or $Args.Count -lt 1 -or [string]::IsNullOrWhiteSpace($Args[0])) {
  Write-Error "Error: Missing required TICKET-ID argument."
  exit 1
}

$ticketId = $Args[0].Trim()

$checkScript = Join-Path $PSScriptRoot 'check-ticket.ps1'
if (-not (Test-Path $checkScript)) {
  Write-Error "Error: Missing script: $checkScript"
  exit 1
}

$jsonText = & $checkScript -Json $ticketId
$paths = $jsonText | ConvertFrom-Json

$templateDir = Join-Path $paths.REPO_ROOT 'templates/ticket-mode'

function Ensure-FromTemplate {
  param(
    [string]$TemplateName,
    [string]$DestPath
  )

  if (Test-Path $DestPath) { return $false }

  $templatePath = Join-Path $templateDir $TemplateName
  if (-not (Test-Path $templatePath)) {
    New-Item -ItemType File -Path $DestPath -Force | Out-Null
    return $true
  }

  $content = Get-Content -LiteralPath $templatePath -Raw
  $content = $content.Replace('<TICKET-ID>', $paths.TICKET_ID)
  Set-Content -LiteralPath $DestPath -Value $content -Encoding UTF8
  return $true
}

New-Item -ItemType Directory -Path $paths.PLANNING_DIR -Force | Out-Null

$createdInitial = Ensure-FromTemplate -TemplateName 'planning-initial-plan.template.md' -DestPath $paths.INITIAL_PLAN
$createdDone = Ensure-FromTemplate -TemplateName 'planning-what-has-been-done.template.md' -DestPath $paths.WHAT_DONE

if ($Json) {
  [PSCustomObject]@{
    TICKET_ID = $paths.TICKET_ID
    INITIAL_PLAN = $paths.INITIAL_PLAN
    WHAT_DONE = $paths.WHAT_DONE
    CREATED = @{
      INITIAL_PLAN = $createdInitial
      WHAT_DONE = $createdDone
    }
  } | ConvertTo-Json -Compress
} else {
  Write-Output "TICKET_ID: $($paths.TICKET_ID)"
  Write-Output "INITIAL_PLAN: $($paths.INITIAL_PLAN) (created=$createdInitial)"
  Write-Output "WHAT_DONE: $($paths.WHAT_DONE) (created=$createdDone)"
}
