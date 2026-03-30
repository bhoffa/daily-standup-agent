#!/bin/bash
# daily-standup.sh — Run the ops standup agent via Claude Code
# Usage: ./daily-standup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_PROMPT="$SCRIPT_DIR/daily-standup-agent.md"
NOTES_FILE="$SCRIPT_DIR/standup-notes.md"
LOG_DIR="$HOME/logs"
LOG_FILE="$LOG_DIR/daily-standup.log"
DATE=$(date +%Y-%m-%d)
OUTPUT_FILE="$SCRIPT_DIR/standup-${DATE}.md"

# Locate claude binary
CLAUDE_BIN=$(command -v claude 2>/dev/null \
  || ls /usr/local/bin/claude 2>/dev/null \
  || ls "$HOME/.local/bin/claude" 2>/dev/null \
  || ls "$HOME/.npm-global/bin/claude" 2>/dev/null \
  || { echo "[ERROR] claude binary not found. Add it to PATH."; exit 1; })

mkdir -p "$LOG_DIR"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

# Build prompt with optional manual notes
NOTES_MSG=""
if [ -f "$NOTES_FILE" ] && [ -s "$NOTES_FILE" ]; then
  NOTES_CONTENT=$(cat "$NOTES_FILE")
  NOTES_MSG="Manual standup notes to incorporate: $NOTES_CONTENT "
fi

MESSAGE="Generate my daily ops standup for ${DATE}. ${NOTES_MSG}Pull from all available sources (Granola, Slack, Linear, Google Calendar). Be concise and prioritize by business impact. Output ONLY the formatted standup post."

log "Generating standup for $DATE..."

# Run Claude in print mode with agent prompt as system instructions
"$CLAUDE_BIN" --dangerously-skip-permissions \
  -p "$MESSAGE" \
  --append-system-prompt-file "$AGENT_PROMPT" \
  | tee "$OUTPUT_FILE"

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -eq 0 ]; then
  log "Standup generated successfully. Saved to: $OUTPUT_FILE"

  # Post to Slack via webhook
  WEBHOOK_URL="${SLACK_STANDUP_WEBHOOK:-}"
  if [ -n "$WEBHOOK_URL" ] && [ -f "$OUTPUT_FILE" ]; then
    STANDUP_TEXT=$(cat "$OUTPUT_FILE")
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
      -X POST -H 'Content-type: application/json' \
      --data "$(jq -n --arg text "$STANDUP_TEXT" '{text: $text}')" \
      "$WEBHOOK_URL")
    if [ "$HTTP_CODE" = "200" ]; then
      log "Standup posted to Slack."
    else
      log "WARNING: Slack post failed (HTTP $HTTP_CODE)"
    fi
  else
    log "WARNING: SLACK_STANDUP_WEBHOOK not set — skipping Slack post."
  fi

  # Clear notes file after successful run
  if [ -f "$NOTES_FILE" ] && [ -s "$NOTES_FILE" ]; then
    log "Clearing standup-notes.md"
    > "$NOTES_FILE"
  fi
else
  log "ERROR: Claude exited with code $EXIT_CODE"
fi

exit $EXIT_CODE
