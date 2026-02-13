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
  Write-Host "Usage: ./ensure-ticket-reviews.ps1 [-Json] <TICKET-ID>"
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

function New-FromTemplate {
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

New-Item -ItemType Directory -Path $paths.REVIEWS_DIR -Force | Out-Null

$prReview = Join-Path $paths.REVIEWS_DIR 'pr-review.md'
$prResp = Join-Path $paths.REVIEWS_DIR 'pr-response.md'
$copilotReview = Join-Path $paths.REVIEWS_DIR 'copilot-review.md'
$copilotResp = Join-Path $paths.REVIEWS_DIR 'copilot-response.md'

$created = [ordered]@{
  'pr-review.md' = (New-FromTemplate -TemplateName 'reviews-pr-review.template.md' -DestPath $prReview)
  'pr-response.md' = (New-FromTemplate -TemplateName 'reviews-pr-response.template.md' -DestPath $prResp)
  'copilot-review.md' = (New-FromTemplate -TemplateName 'reviews-copilot-review.template.md' -DestPath $copilotReview)
  'copilot-response.md' = (New-FromTemplate -TemplateName 'reviews-copilot-response.template.md' -DestPath $copilotResp)
}

if ($Json) {
  [PSCustomObject]@{
    TICKET_ID = $paths.TICKET_ID
    REVIEWS_DIR = $paths.REVIEWS_DIR
    FILES = @{
      PR_REVIEW = $prReview
      PR_RESPONSE = $prResp
      COPILOT_REVIEW = $copilotReview
      COPILOT_RESPONSE = $copilotResp
    }
    CREATED = $created
  } | ConvertTo-Json -Compress
} else {
  Write-Output "TICKET_ID: $($paths.TICKET_ID)"
  $created.GetEnumerator() | ForEach-Object {
    Write-Output ("{0} created={1}" -f $_.Key, $_.Value)
  }
}
