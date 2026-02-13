---
description: Create or update ticket planning documents under `tasks/<TICKET-ID>/planning/`.
scripts:
  sh: scripts/bash/ensure-ticket-plan.sh --json "{ARGS}"
  ps: scripts/powershell/ensure-ticket-plan.ps1 -Json "{ARGS}"
---

## User Input

```text
$ARGUMENTS
```

## Goal

Ensure the following planning documents exist for the ticket (create if missing; do not overwrite):
- `planning/initial-plan.md`
- `planning/what-has-been-done.md`

## Operating constraints

- SAFE / NON-DESTRUCTIVE: never overwrite existing planning docs.

## Outline

1. Run `{SCRIPT}` to resolve ticket paths.
2. Create missing planning docs from templates.
3. Report what was created vs already present.
