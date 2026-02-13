---
description: Initialize append-only review logs under `tasks/<TICKET-ID>/reviews/`.
scripts:
  sh: scripts/bash/ensure-ticket-reviews.sh --json "{ARGS}"
  ps: scripts/powershell/ensure-ticket-reviews.ps1 -Json "{ARGS}"
---

## User Input

```text
$ARGUMENTS
```

## Goal

Ensure the review log files exist (create if missing; do not overwrite):
- `reviews/pr-review.md`
- `reviews/pr-response.md`
- `reviews/copilot-review.md`
- `reviews/copilot-response.md`

## Operating constraints

- Append-only intent: never overwrite existing review logs.

## Outline

1. Run `{SCRIPT}` to resolve ticket paths.
2. Create missing review logs from templates.
3. Report what was created.
