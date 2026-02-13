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

find_repo_root() {
  local dir="$1"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.git" ] || [ -d "$dir/.specify" ]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
else
  REPO_ROOT="$(find_repo_root "$SCRIPT_DIR")"
  if [ -z "$REPO_ROOT" ]; then
    echo "Error: Could not determine repository root." >&2
    exit 1
  fi
fi

cd "$REPO_ROOT"

TASKS_DIR="$REPO_ROOT/tasks"
TICKET_DIR="$TASKS_DIR/$TICKET_ID"

if [ ! -d "$TICKET_DIR" ]; then
  echo "Error: Ticket directory not found: $TICKET_DIR" >&2
  exit 2
fi

REFERENCES_DIR="$TICKET_DIR/references"
PLANNING_DIR="$TICKET_DIR/planning"
REVIEWS_DIR="$TICKET_DIR/reviews"
STEPS_DIR="$PLANNING_DIR/steps"

TICKET_FILE="$TICKET_DIR/ticket.md"
INITIAL_PLAN="$PLANNING_DIR/initial-plan.md"
WHAT_DONE="$PLANNING_DIR/what-has-been-done.md"
METADATA_FILE="$TICKET_DIR/metadata.yaml"

metadata_path=""
if [ -f "$METADATA_FILE" ]; then
  metadata_path="$METADATA_FILE"
fi

if [ "$JSON_MODE" = true ]; then
  printf '{"TICKET_ID":"%s","REPO_ROOT":"%s","TASKS_DIR":"%s","TICKET_DIR":"%s","TICKET_FILE":"%s","METADATA_FILE":"%s","REFERENCES_DIR":"%s","PLANNING_DIR":"%s","STEPS_DIR":"%s","INITIAL_PLAN":"%s","WHAT_DONE":"%s","REVIEWS_DIR":"%s"}\n' \
    "$TICKET_ID" "$REPO_ROOT" "$TASKS_DIR" "$TICKET_DIR" "$TICKET_FILE" "$metadata_path" \
    "$REFERENCES_DIR" "$PLANNING_DIR" "$STEPS_DIR" "$INITIAL_PLAN" "$WHAT_DONE" "$REVIEWS_DIR"
else
  echo "TICKET_ID: $TICKET_ID"
  echo "TICKET_DIR: $TICKET_DIR"
fi
