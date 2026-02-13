---
description: Initialize append-only review logs under `tasks/<TICKET-ID>/reviews/`.
scripts:
  sh: scripts/bash/check-ticket.sh --json "{ARGS}"
  ps: scripts/powershell/check-ticket.ps1 -Json "{ARGS}"
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

1. Run `{SCRIPT}` to resolve ticket paths and parse JSON.
2. Create the `reviews/` directory if missing.
3. Create missing files from templates:
   - `templates/ticket-mode/reviews-pr-review.template.md`
   - `templates/ticket-mode/reviews-pr-response.template.md`
   - `templates/ticket-mode/reviews-copilot-review.template.md`
   - `templates/ticket-mode/reviews-copilot-response.template.md`
4. Report what was created.
