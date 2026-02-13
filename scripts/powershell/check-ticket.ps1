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
  Write-Host "Usage: ./check-ticket.ps1 [-Json] <TICKET-ID>"
  exit 0
}

if (-not $Args -or $Args.Count -lt 1 -or [string]::IsNullOrWhiteSpace($Args[0])) {
  Write-Error "Error: Missing required TICKET-ID argument."
  exit 1
}

$ticketId = $Args[0].Trim()

function Find-RepositoryRoot {
  param(
    [string]$StartDir,
    [string[]]$Markers = @('.git', '.specify')
  )
  $current = Resolve-Path $StartDir
  while ($true) {
    foreach ($marker in $Markers) {
      if (Test-Path (Join-Path $current $marker)) {
        return $current
      }
    }
    $parent = Split-Path $current -Parent
    if ($parent -eq $current) { return $null }
    $current = $parent
  }
}

$repoRoot = Find-RepositoryRoot -StartDir $PSScriptRoot
if (-not $repoRoot) {
  Write-Error "Error: Could not determine repository root."
  exit 1
}

try {
  $gitRoot = git rev-parse --show-toplevel 2>$null
  if ($LASTEXITCODE -eq 0) { $repoRoot = $gitRoot }
} catch {
  # ignore
}

Set-Location $repoRoot

$tasksDir = Join-Path $repoRoot 'tasks'
$ticketDir = Join-Path $tasksDir $ticketId

if (-not (Test-Path $ticketDir)) {
  Write-Error "Error: Ticket directory not found: $ticketDir"
  exit 2
}

$referencesDir = Join-Path $ticketDir 'references'
$planningDir = Join-Path $ticketDir 'planning'
$reviewsDir = Join-Path $ticketDir 'reviews'
$stepsDir = Join-Path $planningDir 'steps'

$ticketFile = Join-Path $ticketDir 'ticket.md'
$initialPlan = Join-Path $planningDir 'initial-plan.md'
$whatDone = Join-Path $planningDir 'what-has-been-done.md'
$metadataFile = Join-Path $ticketDir 'metadata.yaml'

if ($Json) {
  [PSCustomObject]@{
    TICKET_ID       = $ticketId
    REPO_ROOT       = $repoRoot
    TASKS_DIR       = $tasksDir
    TICKET_DIR      = $ticketDir
    TICKET_FILE     = $ticketFile
    METADATA_FILE   = (Get-Item -LiteralPath $metadataFile -ErrorAction SilentlyContinue)?.FullName
    REFERENCES_DIR  = $referencesDir
    PLANNING_DIR    = $planningDir
    STEPS_DIR       = $stepsDir
    INITIAL_PLAN    = $initialPlan
    WHAT_DONE       = $whatDone
    REVIEWS_DIR     = $reviewsDir
  } | ConvertTo-Json -Compress
} else {
  Write-Output "TICKET_ID: $ticketId"
  Write-Output "TICKET_DIR: $ticketDir"
}
