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
      echo "Usage: $0 [--json] <TICKET-ID>";
      exit 0
      ;;
    *)
      ARGS+=("$arg")
      ;;
  esac
  i=$((i + 1))
done

TICKET_ID="${ARGS[0]}"
if [ -z "$TICKET_ID" ]; then
  echo "Error: Missing required TICKET-ID argument." >&2
  exit 1
fi

# resolve paths
PATHS_JSON="$(scripts/bash/check-ticket.sh --json "$TICKET_ID")"

# simple json field extractor (no jq dependency)
json_field() {
  local name="$1"
  echo "$PATHS_JSON" | sed -n "s/.*\"$name\":\"\([^\"]*\)\".*/\1/p"
}

REPO_ROOT="$(json_field REPO_ROOT)"
PLANNING_DIR="$(json_field PLANNING_DIR)"
INITIAL_PLAN="$(json_field INITIAL_PLAN)"
WHAT_DONE="$(json_field WHAT_DONE)"

TEMPLATE_DIR="$REPO_ROOT/templates/ticket-mode"

mkdir -p "$PLANNING_DIR"

created_initial=false
created_done=false

if [ ! -f "$INITIAL_PLAN" ]; then
  if [ -f "$TEMPLATE_DIR/planning-initial-plan.template.md" ]; then
    sed "s/<TICKET-ID>/$TICKET_ID/g" "$TEMPLATE_DIR/planning-initial-plan.template.md" > "$INITIAL_PLAN"
  else
    : > "$INITIAL_PLAN"
  fi
  created_initial=true
fi

if [ ! -f "$WHAT_DONE" ]; then
  if [ -f "$TEMPLATE_DIR/planning-what-has-been-done.template.md" ]; then
    sed "s/<TICKET-ID>/$TICKET_ID/g" "$TEMPLATE_DIR/planning-what-has-been-done.template.md" > "$WHAT_DONE"
  else
    : > "$WHAT_DONE"
  fi
  created_done=true
fi

if [ "$JSON_MODE" = true ]; then
  printf '{"TICKET_ID":"%s","INITIAL_PLAN":"%s","WHAT_DONE":"%s","CREATED":{"INITIAL_PLAN":%s,"WHAT_DONE":%s}}\n' \
    "$TICKET_ID" "$INITIAL_PLAN" "$WHAT_DONE" "$created_initial" "$created_done"
else
  echo "TICKET_ID: $TICKET_ID"
  echo "INITIAL_PLAN: $INITIAL_PLAN (created=$created_initial)"
  echo "WHAT_DONE: $WHAT_DONE (created=$created_done)"
fi
