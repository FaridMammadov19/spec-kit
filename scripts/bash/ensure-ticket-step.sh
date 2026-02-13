#!/usr/bin/env bash

set -e

JSON_MODE=false
ARGS=()

i=1
while [ $i -le $# ]; do
  arg="${!i}"
  case "$arg" in
    --json)
      JSON_MODE=true
      ;;
    --help|-h)
      echo "Usage: $0 [--json] <TICKET-ID> <STEP-NAME>";
      exit 0
      ;;
    *)
      ARGS+=("$arg")
      ;;
  esac
  i=$((i + 1))
done

TICKET_ID="${ARGS[0]}"
STEP_NAME="${ARGS[@]:1}"

if [ -z "$TICKET_ID" ]; then
  TICKET_ID="TOUR-xxxx"
fi

if [ -z "$STEP_NAME" ]; then
  echo "Error: STEP-NAME cannot be empty." >&2
  exit 1
fi

# slugify
slug() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//' | sed 's/-$//'
}

STEP_SLUG="$(slug "$STEP_NAME")"
if [ -z "$STEP_SLUG" ]; then STEP_SLUG="step"; fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$REPO_ROOT" ]; then
  REPO_ROOT="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

# Ensure ticket exists (non-destructive)
TICKET_JSON="$(scripts/bash/create-new-ticket.sh --json "$TICKET_ID")"

json_field() {
  local name="$1"
  echo "$TICKET_JSON" | sed -n "s/.*\"$name\":\"\([^\"]*\)\".*/\1/p"
}

STEPS_DIR="$(json_field STEPS_DIR)"
mkdir -p "$STEPS_DIR"

STEP_FILE="$STEPS_DIR/$STEP_SLUG.md"
TEMPLATE="$REPO_ROOT/templates/ticket-mode/planning-step.template.md"

created=false
if [ ! -f "$STEP_FILE" ]; then
  if [ -f "$TEMPLATE" ]; then
    # replace tokens; escape delimiter minimally
    sed -e "s/<TICKET-ID>/$TICKET_ID/g" -e "s/<STEP-NAME>/$STEP_NAME/g" "$TEMPLATE" > "$STEP_FILE"
  else
    : > "$STEP_FILE"
  fi
  created=true
fi

if [ "$JSON_MODE" = true ]; then
  printf '{"TICKET_ID":"%s","STEP_NAME":"%s","STEP_SLUG":"%s","STEP_FILE":"%s","CREATED":%s}\n' \
    "$TICKET_ID" "$STEP_NAME" "$STEP_SLUG" "$STEP_FILE" "$created"
else
  echo "TICKET_ID: $TICKET_ID"
  echo "STEP_FILE: $STEP_FILE (created=$created)"
fi
