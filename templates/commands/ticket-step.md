---
description: Create a planning step document under `tasks/<TICKET-ID>/planning/steps/`.
scripts:
  sh: scripts/bash/ensure-ticket-step.sh --json "{ARGS}"
  ps: scripts/powershell/ensure-ticket-step.ps1 -Json "{ARGS}"
---

## User Input

```text
$ARGUMENTS
```

## Usage

Preferred:
- `/speckit.ticket-step <TICKET-ID> <STEP-NAME>`

If no ticket id exists yet, you may use the placeholder:
- `/speckit.ticket-step TOUR-xxxx <STEP-NAME>`

## Goal

- Ensure the ticket workspace exists under `tasks/<TICKET-ID>/`.
- Create `planning/steps/<step-slug>.md` from `templates/ticket-mode/planning-step.template.md` if missing.
- Never overwrite an existing step file.

## Outline

1. Run `{SCRIPT}` with args.
2. Read JSON output for `STEP_FILE` and `CREATED`.
3. Report the step path.
