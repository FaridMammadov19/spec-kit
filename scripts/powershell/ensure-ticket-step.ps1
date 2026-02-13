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
  Write-Host "Usage: ./ensure-ticket-step.ps1 [-Json] <TICKET-ID> <STEP-NAME>"
  exit 0
}

if (-not $Args -or $Args.Count -lt 2) {
  Write-Error "Error: Expected <TICKET-ID> and <STEP-NAME>."
  exit 1
}

$ticketId = ($Args[0] ?? '').Trim()
$stepNameRaw = ($Args[1..($Args.Count-1)] -join ' ').Trim()

if ([string]::IsNullOrWhiteSpace($ticketId)) { $ticketId = 'TOUR-xxxx' }
if ([string]::IsNullOrWhiteSpace($stepNameRaw)) {
  Write-Error "Error: STEP-NAME cannot be empty."
  exit 1
}

function ConvertTo-StepSlug {
  param([string]$Value)
  $s = $Value.ToLowerInvariant()
  $s = [Text.RegularExpressions.Regex]::Replace($s, '[^a-z0-9]+', '-')
  $s = [Text.RegularExpressions.Regex]::Replace($s, '-{2,}', '-')
  $s = $s.Trim('-')
  if ($s.Length -eq 0) { $s = 'step' }
  return $s
}

$stepSlug = ConvertTo-StepSlug $stepNameRaw

$repoRoot = $null
try {
  $repoRoot = git rev-parse --show-toplevel 2>$null
  if ($LASTEXITCODE -ne 0) { $repoRoot = $null }
} catch {}

if (-not $repoRoot) {
  # fallback: go up from scripts/powershell
  $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
}

$createTicket = Join-Path $repoRoot 'scripts/powershell/create-new-ticket.ps1'
if (-not (Test-Path $createTicket)) {
  Write-Error "Error: Missing create-new-ticket.ps1 at $createTicket"
  exit 1
}

# Ensure ticket workspace exists (non-destructive)
$ticketJson = & $createTicket -Json $ticketId
$ticket = $ticketJson | ConvertFrom-Json

New-Item -ItemType Directory -Path $ticket.STEPS_DIR -Force | Out-Null

$stepFile = Join-Path $ticket.STEPS_DIR ("$stepSlug.md")
$templatePath = Join-Path $repoRoot 'templates/ticket-mode/planning-step.template.md'

$created = $false
if (-not (Test-Path $stepFile)) {
  if (Test-Path $templatePath) {
    $content = Get-Content -LiteralPath $templatePath -Raw
    $content = $content.Replace('<TICKET-ID>', $ticket.TICKET_ID)
    $content = $content.Replace('<STEP-NAME>', $stepNameRaw)
    Set-Content -LiteralPath $stepFile -Value $content -Encoding UTF8
  } else {
    New-Item -ItemType File -Path $stepFile -Force | Out-Null
  }
  $created = $true
}

if ($Json) {
  [PSCustomObject]@{
    TICKET_ID = $ticket.TICKET_ID
    STEP_NAME = $stepNameRaw
    STEP_SLUG = $stepSlug
    STEP_FILE = $stepFile
    CREATED = $created
  } | ConvertTo-Json -Compress
} else {
  Write-Output "TICKET_ID: $($ticket.TICKET_ID)"
  Write-Output "STEP_FILE: $stepFile (created=$created)"
}
