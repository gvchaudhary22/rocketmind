#!/usr/bin/env bash
# RocketMind Snapshot Utility — Serializes current session context for persistence

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="$ROOT_DIR/.rocketmind/state"
SNAPSHOT_FILE="$STATE_DIR/snapshot.json"

mkdir -p "$STATE_DIR"

echo "📸 Creating RocketMind session snapshot..."

# Collect current state
PROJECT_NAME=$(jq -r '.project.name // "RocketMind"' "$ROOT_DIR/rocketmind.config.json" 2>/dev/null || echo "RocketMind")
CURRENT_STATE=$(cat "$STATE_DIR/STATE.md" 2>/dev/null || echo "# Initial State")
LAST_COMMITS=$(git log -n 5 --oneline 2>/dev/null || echo "No commits yet")
LAST_ERROR=$(cat "$STATE_DIR/last_error.json" 2>/dev/null || echo "{}")

# Serialize metadata
jq -n \
  --arg project "$PROJECT_NAME" \
  --arg state "$CURRENT_STATE" \
  --arg git "$LAST_COMMITS" \
  --arg error "$LAST_ERROR" \
  --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  '{
    project: $project,
    state: $state,
    git_history: $git,
    last_error: $error,
    snapshot_at: $timestamp,
    version: "2.1.0"
  }' > "$SNAPSHOT_FILE"

echo "✅ Snapshot written to $SNAPSHOT_FILE"
