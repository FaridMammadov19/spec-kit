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

PATHS_JSON="$(scripts/bash/check-ticket.sh --json "$TICKET_ID")"

json_field() {
  local name="$1"
  echo "$PATHS_JSON" | sed -n "s/.*\"$name\":\"\([^\"]*\)\".*/\1/p"
}

REPO_ROOT="$(json_field REPO_ROOT)"
REVIEWS_DIR="$(json_field REVIEWS_DIR)"

TEMPLATE_DIR="$REPO_ROOT/templates/ticket-mode"

mkdir -p "$REVIEWS_DIR"

create_if_missing() {
  local template="$1"
  local dest="$2"
  local created=false

  if [ ! -f "$dest" ]; then
    if [ -f "$template" ]; then
      sed "s/<TICKET-ID>/$TICKET_ID/g" "$template" > "$dest"
    else
      : > "$dest"
    fi
    created=true
  fi

  echo "$created"
}

pr_review_created=$(create_if_missing "$TEMPLATE_DIR/reviews-pr-review.template.md" "$REVIEWS_DIR/pr-review.md")
pr_response_created=$(create_if_missing "$TEMPLATE_DIR/reviews-pr-response.template.md" "$REVIEWS_DIR/pr-response.md")
copilot_review_created=$(create_if_missing "$TEMPLATE_DIR/reviews-copilot-review.template.md" "$REVIEWS_DIR/copilot-review.md")
copilot_response_created=$(create_if_missing "$TEMPLATE_DIR/reviews-copilot-response.template.md" "$REVIEWS_DIR/copilot-response.md")

if [ "$JSON_MODE" = true ]; then
  printf '{"TICKET_ID":"%s","REVIEWS_DIR":"%s","CREATED":{"pr-review.md":%s,"pr-response.md":%s,"copilot-review.md":%s,"copilot-response.md":%s}}\n' \
    "$TICKET_ID" "$REVIEWS_DIR" "$pr_review_created" "$pr_response_created" "$copilot_review_created" "$copilot_response_created"
else
  echo "TICKET_ID: $TICKET_ID"
  echo "reviews/pr-review.md created=$pr_review_created"
  echo "reviews/pr-response.md created=$pr_response_created"
  echo "reviews/copilot-review.md created=$copilot_review_created"
  echo "reviews/copilot-response.md created=$copilot_response_created"
fi
