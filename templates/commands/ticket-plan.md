---
description: Create or update ticket planning documents under `tasks/<TICKET-ID>/planning/`.
scripts:
  sh: scripts/bash/check-ticket.sh --json "{ARGS}"
  ps: scripts/powershell/check-ticket.ps1 -Json "{ARGS}"
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
- If files are missing, create them from `templates/ticket-mode/*`.

## Outline

1. Run `{SCRIPT}` to resolve ticket paths and parse JSON.
2. If `INITIAL_PLAN` or `WHAT_DONE` paths do not exist on disk, create them from templates:
   - `templates/ticket-mode/planning-initial-plan.template.md`
   - `templates/ticket-mode/planning-what-has-been-done.template.md`
3. Report what was created vs already present.
