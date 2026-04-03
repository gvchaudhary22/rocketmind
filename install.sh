#!/usr/bin/env bash
# RocketMind Installation Script v2.0.0
# Shiprocket Engineering Standard — agentic framework
set -e

FRAMEWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_MODE="local"
TOOL="claude"
PROJECT_DIR="${PWD}"
SKIP_VERIFY=0
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'

QUIET=0
INSTALL_HOOKS_ONLY=0

while [[ $# -gt 0 ]]; do
  case $1 in
    --global|-g)   INSTALL_MODE="global"; shift ;;
    --local|-l)    INSTALL_MODE="local";  shift ;;
    --tool)        TOOL="$2"; shift 2 ;;
    --all)         TOOL="all"; shift ;;
    --hooks-only)  INSTALL_HOOKS_ONLY=1; shift ;;
    --skip-verify) SKIP_VERIFY=1; shift ;;
    --quiet|-q)    QUIET=1; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# When --quiet: suppress banner, per-file progress, and summary.
# Still print errors (>&2). Used by setup.sh to avoid output mixing.
qecho() { [[ "$QUIET" -eq 0 ]] && echo -e "$@" || true; }
# qrun: run a command, suppressing stdout when quiet (stderr still visible for errors)
qrun() { if [[ "$QUIET" -eq 1 ]]; then "$@" >/dev/null; else "$@"; fi; }

install_git_lifecycle_hooks() {
  if [[ "$INSTALL_MODE" != "local" ]]; then
    return 0
  fi

  qecho ""
  qecho "${YELLOW}▶ Installing git lifecycle hooks...${NC}"

  if qrun bash "$FRAMEWORK_DIR/bin/install-hooks.sh" --project-dir "$PROJECT_DIR"; then
    qecho "  ✓ git hooks linked for this repo"
  else
    echo -e "${YELLOW}⚠️  RocketMind git hook installation failed for $PROJECT_DIR${NC}" >&2
    echo -e "${YELLOW}   Run manually: bash bin/install-hooks.sh --project-dir \"$PROJECT_DIR\"${NC}" >&2
  fi
}

write_runtime_adapter_contract() {
  local runtime="$1"
  local target_dir="$2"
  qrun node "$FRAMEWORK_DIR/bin/runtime-adapter.js" \
    --runtime "$runtime" --output "$target_dir/adapter.contract.json"
  qecho "  ✓ adapter.contract.json ($runtime capability contract)"
}

if [[ "$INSTALL_MODE" == "global" ]]; then
  CLAUDE_DIR="$HOME/.claude"
else
  CLAUDE_DIR="$PROJECT_DIR/.claude"
fi

qecho "${BOLD}"
qecho "╔════════════════════════════════════════╗"
qecho "║   RocketMind Installer v2.0.0   ║"
qecho "║   Shiprocket AI Engineering Standard      ║"
qecho "╚════════════════════════════════════════╝"
qecho "${NC}"

# ─── Checksum Verification ───────────────────────────────────────────────────
# Verifies framework files against the published SHASUM256.txt manifest.
# Requires: curl, shasum (both available by default on macOS and most Linux distros).
# Skip with --skip-verify (prints a prominent warning).
verify_checksums() {
  local manifest="$FRAMEWORK_DIR/SHASUM256.txt"

  if [[ "$SKIP_VERIFY" -eq 1 ]]; then
    qecho "${YELLOW}⚠️  WARNING: --skip-verify flag is set. Checksum verification SKIPPED.${NC}"
    qecho "${YELLOW}   Only use this in local development. Never skip in production installs.${NC}"
    return 0
  fi

  # If a local manifest exists (e.g. cloned repo), verify against it
  if [[ -f "$manifest" ]]; then
    qecho "${YELLOW}▶ Verifying framework file integrity...${NC}"
    # Run shasum check from the framework dir so relative paths resolve
    if (cd "$FRAMEWORK_DIR" && shasum -a 256 --check SHASUM256.txt --quiet 2>&1); then
      qecho "${GREEN}  ✅ All checksums verified${NC}"
    else
      echo -e "${RED}  ❌ Checksum mismatch detected — aborting installation.${NC}" >&2
      echo -e "${RED}     One or more framework files do not match the published manifest.${NC}" >&2
      echo -e "${RED}     Download a fresh copy from: https://github.com/shiprocket/rocketmind/releases${NC}" >&2
      exit 1
    fi
  else
    # No local manifest — skip silently (expected for source checkouts without a release)
    qecho "${BLUE}  ℹ  No SHASUM256.txt found — skipping integrity check (source install).${NC}"
  fi
}

# ─── Install for Claude Code ──────────────────────────────────────────────────
install_for_claude() {
  qecho "${YELLOW}▶ Installing for Claude Code...${NC}"

  # Core directories
  mkdir -p \
    "$CLAUDE_DIR/commands/rocketmind" \
    "$CLAUDE_DIR/agents" \
    "$CLAUDE_DIR/skills" \
    "$CLAUDE_DIR/state" \
    "$CLAUDE_DIR/rocketmind/hooks"

  # ── Orchestrator (generated from template at install time) ────────────────
  # Written to .claude/CLAUDE.md (Claude Code's project-level instructions)
  # Also written to the project root so Claude Code auto-detects it on open.
  # Both are gitignored — this file is always generated, never committed.
  qrun node "$FRAMEWORK_DIR/bin/generate-instructions.js" \
    --runtime claude --output "$CLAUDE_DIR/CLAUDE.md"
  qrun node "$FRAMEWORK_DIR/bin/generate-instructions.js" \
    --runtime claude --output "$PROJECT_DIR/CLAUDE.md"
  qecho "  ✓ CLAUDE.md (generated for Claude runtime → .claude/ + project root)"

  # ── Human-view files (generated from registry + templates at install time) ─
  qrun node "$FRAMEWORK_DIR/bin/generate-instructions.js" --human-views
  qecho "  ✓ INSTRUCTIONS.md, SKILLS.md, WORKFLOWS.md (generated from registry)"

  # ── Control Plane ─────────────────────────────────────────────────────────
  cp "$FRAMEWORK_DIR/INSTRUCTIONS.md" "$CLAUDE_DIR/INSTRUCTIONS.md"
  cp "$FRAMEWORK_DIR/SKILLS.md" "$CLAUDE_DIR/SKILLS.md"
  cp "$FRAMEWORK_DIR/WORKFLOWS.md" "$CLAUDE_DIR/WORKFLOWS.md"
  cp "$FRAMEWORK_DIR/rocketmind.registry.json" "$CLAUDE_DIR/rocketmind.registry.json"
  cp "$FRAMEWORK_DIR/rocketmind.config.schema.json" "$CLAUDE_DIR/rocketmind.config.schema.json"
  write_runtime_adapter_contract "claude" "$CLAUDE_DIR"
  qecho "  ✓ control plane docs + registry + schema"

  # ── Core Agents ───────────────────────────────────────────────────────────
  for f in "$FRAMEWORK_DIR"/agents/*.md; do
    name=$(basename "$f")
    cp "$f" "$CLAUDE_DIR/agents/$name"
    qecho "  ✓ agents/$name"
  done
  qecho "  ✓ agents/ ($(ls "$FRAMEWORK_DIR/agents/"*.md | wc -l | tr -d ' ') files)"

  # ── Forged Specialist Agents ───────────────────────────────────────────────
  if [[ -d "$FRAMEWORK_DIR/forge" ]]; then
    mkdir -p "$CLAUDE_DIR/agents/forge"
    for f in "$FRAMEWORK_DIR"/forge/*.md; do
      name=$(basename "$f")
      cp "$f" "$CLAUDE_DIR/agents/forge/$name"
      qecho "  ✓ agents/forge/$name"
    done
  fi

  # ── Skills ────────────────────────────────────────────────────────────────
  for f in "$FRAMEWORK_DIR"/skills/*.md; do
    name=$(basename "$f")
    cp "$f" "$CLAUDE_DIR/skills/$name"
    qecho "  ✓ skills/$name"
  done
  qecho "  ✓ skills/ ($(ls "$FRAMEWORK_DIR/skills/"*.md | wc -l | tr -d ' ') files)"

  # ── Commands ──────────────────────────────────────────────────────────────
  cp "$FRAMEWORK_DIR/commands/commands.md" "$CLAUDE_DIR/commands/rocketmind/commands.md"
  qecho "  ✓ commands/rocketmind/commands.md"

  # Generate individual command files
  local commands=(
    new-project plan build verify ship next quick forge review audit
    monitor debug map-codebase progress resume deploy rollback
    riper worktree cost ask
  )
  for cmd in "${commands[@]}"; do
    cat > "$CLAUDE_DIR/commands/rocketmind/${cmd}.md" << CMDEOF
---
description: "RocketMind /rocketmind:${cmd} — AI agent orchestration"
allowed-tools: all
---
Read \$CLAUDE_DIR/CLAUDE.md to load RocketMind context.
Read \$CLAUDE_DIR/commands/rocketmind/commands.md for this command's exact process specification.
If STATE.md exists at .rocketmind/state/STATE.md, read it for project context.
If DECISIONS-LOG.md exists at .rocketmind/state/DECISIONS-LOG.md, append durable decision history there.
Execute: /rocketmind:${cmd} \$ARGUMENTS — follow the exact process defined, no shortcuts.
CMDEOF
    qecho "  ✓ /rocketmind:${cmd}"
  done
  qecho "  ✓ commands/ (${#commands[@]} commands)"

  # ── State Template ────────────────────────────────────────────────────────
  cp "$FRAMEWORK_DIR/templates/STATE.md" "$CLAUDE_DIR/state/STATE.template.md"
  cp "$FRAMEWORK_DIR/templates/DECISIONS-LOG.md" "$CLAUDE_DIR/state/DECISIONS-LOG.template.md"
  cp "$FRAMEWORK_DIR/templates/OPERATIONAL-RULES.json" "$CLAUDE_DIR/state/OPERATIONAL-RULES.template.json"
  qecho "  ✓ state/STATE.template.md"
  qecho "  ✓ state/DECISIONS-LOG.template.md"
  qecho "  ✓ state/OPERATIONAL-RULES.template.json"

  # ── Hook Scripts ──────────────────────────────────────────────────────────
  qecho ""
  qecho "${YELLOW}▶ Installing lifecycle hooks...${NC}"
  for f in "$FRAMEWORK_DIR"/hooks/scripts/*.sh; do
    name=$(basename "$f")
    cp "$f" "$CLAUDE_DIR/rocketmind/hooks/$name"
    chmod +x "$CLAUDE_DIR/rocketmind/hooks/$name"
    qecho "  ✓ hooks/$name"
  done

  # ── Claude Code Settings (hooks registration) ─────────────────────────────
  qecho ""
  qecho "${YELLOW}▶ Configuring Claude Code settings...${NC}"
  install_claude_settings

  qecho "${GREEN}  ✅ Claude Code installation complete${NC}"
}

# ─── Install for Codex ───────────────────────────────────────────────────────
install_for_codex() {
  qecho "${YELLOW}▶ Installing for Codex...${NC}"

  local codex_dir
  if [[ "$INSTALL_MODE" == "global" ]]; then
    codex_dir="$HOME/.codex"
  else
    codex_dir="$PROJECT_DIR/.codex"
  fi

  mkdir -p "$codex_dir/agents" "$codex_dir/skills" "$codex_dir/state"

  # Codex operator prompt generated from template at install time.
  qrun node "$FRAMEWORK_DIR/bin/generate-instructions.js" \
    --runtime codex --output "$codex_dir/INSTRUCTIONS.md"
  cp "$FRAMEWORK_DIR/SKILLS.md"                "$codex_dir/SKILLS.md"
  cp "$FRAMEWORK_DIR/WORKFLOWS.md"             "$codex_dir/WORKFLOWS.md"
  cp "$FRAMEWORK_DIR/rocketmind.registry.json"      "$codex_dir/rocketmind.registry.json"
  cp "$FRAMEWORK_DIR/rocketmind.config.json"        "$codex_dir/rocketmind.config.json"
  cp "$FRAMEWORK_DIR/rocketmind.config.schema.json" "$codex_dir/rocketmind.config.schema.json"
  write_runtime_adapter_contract "codex" "$codex_dir"
  cp "$FRAMEWORK_DIR/templates/STATE.md"  "$codex_dir/state/STATE.template.md"
  cp "$FRAMEWORK_DIR/templates/DECISIONS-LOG.md" "$codex_dir/state/DECISIONS-LOG.template.md"
  cp "$FRAMEWORK_DIR/templates/OPERATIONAL-RULES.json" "$codex_dir/state/OPERATIONAL-RULES.template.json"
  qecho "  ✓ operator surface + registry + config + state templates"

  for f in "$FRAMEWORK_DIR"/agents/*.md; do
    cp "$f" "$codex_dir/agents/$(basename "$f")"
  done
  qecho "  ✓ agents/ ($(ls "$FRAMEWORK_DIR/agents/"*.md | wc -l | tr -d ' ') files)"

  for f in "$FRAMEWORK_DIR"/skills/*.md; do
    cp "$f" "$codex_dir/skills/$(basename "$f")"
  done
  qecho "  ✓ skills/ ($(ls "$FRAMEWORK_DIR/skills/"*.md | wc -l | tr -d ' ') files)"

  # Codex policy: injected system context pointing to the RocketMind control plane.
  cat > "$codex_dir/policy.md" << 'POLICY_EOF'
# RocketMind Control Plane — Codex Adapter

You are running the RocketMind orchestration framework.

Read INSTRUCTIONS.md at session start. Your agent registry is rocketmind.registry.json.
Classify the request, select the best agent, dispatch work per WORKFLOWS.md.
Read state/STATE.md on start, write it on session end.
Record durable decisions in state/DECISIONS-LOG.md.
If the user sends a plain prompt that implies tracked work, infer the nearest RocketMind workflow before acting. Explicit `/rocketmind:*` commands still take precedence.

/rocketmind: command equivalents — follow the matching section in WORKFLOWS.md:
  plan → WORKFLOWS.md §plan  |  build → §build  |  verify → §verify  |  ship → §ship
POLICY_EOF
  qecho "  ✓ policy.md (RocketMind adapter context)"
  qecho "${GREEN}  ✅ Codex installation complete → $codex_dir${NC}"
}

# ─── Install for Antigravity ──────────────────────────────────────────────────
# Antigravity reads CLAUDE.md from .antigravity/ — same format as Claude adapter.
install_for_antigravity() {
  qecho "${YELLOW}▶ Installing for Antigravity...${NC}"

  local ag_dir
  if [[ "$INSTALL_MODE" == "global" ]]; then
    ag_dir="$HOME/.antigravity"
  else
    ag_dir="$PROJECT_DIR/.antigravity"
  fi

  mkdir -p "$ag_dir/agents" "$ag_dir/skills" "$ag_dir/state"

  # Antigravity reads CLAUDE.md — generated from the runtime-specific template configuration.
  qrun node "$FRAMEWORK_DIR/bin/generate-instructions.js" \
    --runtime antigravity --output "$ag_dir/CLAUDE.md"
  qecho "  ✓ CLAUDE.md (generated for Antigravity runtime)"

  cp "$FRAMEWORK_DIR/SKILLS.md"                "$ag_dir/SKILLS.md"
  cp "$FRAMEWORK_DIR/WORKFLOWS.md"             "$ag_dir/WORKFLOWS.md"
  cp "$FRAMEWORK_DIR/rocketmind.registry.json"      "$ag_dir/rocketmind.registry.json"
  cp "$FRAMEWORK_DIR/rocketmind.config.json"        "$ag_dir/rocketmind.config.json"
  cp "$FRAMEWORK_DIR/rocketmind.config.schema.json" "$ag_dir/rocketmind.config.schema.json"
  write_runtime_adapter_contract "antigravity" "$ag_dir"
  cp "$FRAMEWORK_DIR/templates/STATE.md"  "$ag_dir/state/STATE.template.md"
  cp "$FRAMEWORK_DIR/templates/DECISIONS-LOG.md" "$ag_dir/state/DECISIONS-LOG.template.md"
  cp "$FRAMEWORK_DIR/templates/OPERATIONAL-RULES.json" "$ag_dir/state/OPERATIONAL-RULES.template.json"
  qecho "  ✓ control plane docs + registry + config + state templates"

  for f in "$FRAMEWORK_DIR"/agents/*.md; do
    cp "$f" "$ag_dir/agents/$(basename "$f")"
  done
  qecho "  ✓ agents/ ($(ls "$FRAMEWORK_DIR/agents/"*.md | wc -l | tr -d ' ') files)"

  for f in "$FRAMEWORK_DIR"/skills/*.md; do
    cp "$f" "$ag_dir/skills/$(basename "$f")"
  done
  qecho "  ✓ skills/ ($(ls "$FRAMEWORK_DIR/skills/"*.md | wc -l | tr -d ' ') files)"

  qecho "${GREEN}  ✅ Antigravity installation complete → $ag_dir${NC}"
}

# ─── Write Claude Code settings.json with hooks ───────────────────────────────
install_claude_settings() {
  local settings_file="$CLAUDE_DIR/settings.json"
  local hdir="$HOME/.claude/rocketmind/hooks"
  local config="$FRAMEWORK_DIR/rocketmind.config.json"

  # Read hook flags from rocketmind.config.json; default true if config absent or jq unavailable
  local hook_post_tool_use=true
  if [[ -f "$config" ]] && command -v jq &>/dev/null; then
    local flag
    flag=$(jq -r '.hooks.post_tool_use // true' "$config")
    [[ "$flag" == "false" ]] && hook_post_tool_use=false
  fi

  # Build the hooks object conditionally — only register enabled hooks
  local post_tool_use_arg="false"
  [[ "$hook_post_tool_use" == true ]] && post_tool_use_arg="true"

  if [[ -f "$settings_file" ]] && command -v jq &>/dev/null; then
    echo "  Found existing settings.json — merging hooks..."
    local tmp_settings
    tmp_settings=$(mktemp)
    jq --arg hdir "$hdir" --argjson post_tool_use "$post_tool_use_arg" '
      .hooks = (
        {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": ("bash \"" + $hdir + "/pre-tool-use.sh\" 2>/dev/null || true")}]}]} +
        (if $post_tool_use then {"PostToolUse": [{"matcher": ".*", "hooks": [{"type": "command", "command": ("bash \"" + $hdir + "/post-tool-use.sh\" 2>/dev/null || true")}]}]} else {} end) +
        {"PreCompact": [{"matcher": ".*", "hooks": [{"type": "command", "command": ("bash \"" + $hdir + "/pre-compact.sh\" 2>/dev/null || true")}]}],
         "Stop":       [{"matcher": ".*", "hooks": [{"type": "command", "command": ("bash \"" + $hdir + "/stop.sh\" 2>/dev/null || true")}]}]}
      )
    ' "$settings_file" > "$tmp_settings" && mv "$tmp_settings" "$settings_file"
  else
    # Write fresh settings using jq so hook flags are respected consistently
    jq -n \
      --arg hdir "$hdir" \
      --argjson post_tool_use "$post_tool_use_arg" \
      '{
        "permissions": {
          "allow": ["Bash(git:*)", "Bash(npm:*)", "Bash(npx:*)", "Bash(node:*)"]
        },
        "hooks": (
          {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": ("bash \"" + $hdir + "/pre-tool-use.sh\" 2>/dev/null || true")}]}]} +
          (if $post_tool_use then {"PostToolUse": [{"matcher": ".*", "hooks": [{"type": "command", "command": ("bash \"" + $hdir + "/post-tool-use.sh\" 2>/dev/null || true")}]}]} else {} end) +
          {"PreCompact": [{"matcher": ".*", "hooks": [{"type": "command", "command": ("bash \"" + $hdir + "/pre-compact.sh\" 2>/dev/null || true")}]}],
           "Stop":       [{"matcher": ".*", "hooks": [{"type": "command", "command": ("bash \"" + $hdir + "/stop.sh\" 2>/dev/null || true")}]}]}
        )
      }' > "$settings_file"
  fi

  local active_hooks="PreToolUse, PreCompact, Stop"
  [[ "$hook_post_tool_use" == true ]] && active_hooks="PreToolUse, PostToolUse, PreCompact, Stop"
  qecho "  ✓ settings.json (hooks: ${active_hooks})"
}

# ─── Initialize project state directory ───────────────────────────────────────
init_project_state() {
  qecho ""
  qecho "${YELLOW}▶ Initializing project state...${NC}"

  local state_dir="$PROJECT_DIR/.rocketmind/state"
  local hooks_dir="$PROJECT_DIR/.rocketmind/hooks"

  mkdir -p "$state_dir" "$hooks_dir" "$PROJECT_DIR/.rocketmind/errors"

  # Copy state templates if missing
  if [[ ! -f "$state_dir/STATE.md" ]]; then
    cp "$FRAMEWORK_DIR/templates/STATE.md" "$state_dir/STATE.md"
    qecho "  ✓ .rocketmind/state/STATE.md (from template)"
  else
    qecho "  ✓ .rocketmind/state/STATE.md (already exists — preserved)"
  fi

  if [[ ! -f "$state_dir/DECISIONS-LOG.md" ]]; then
    cp "$FRAMEWORK_DIR/templates/DECISIONS-LOG.md" "$state_dir/DECISIONS-LOG.md"
    qecho "  ✓ .rocketmind/state/DECISIONS-LOG.md (from template)"
  else
    qecho "  ✓ .rocketmind/state/DECISIONS-LOG.md (already exists — preserved)"
  fi

  if [[ ! -f "$state_dir/OPERATIONAL-RULES.json" ]]; then
    cp "$FRAMEWORK_DIR/templates/OPERATIONAL-RULES.json" "$state_dir/OPERATIONAL-RULES.json"
    qecho "  ✓ .rocketmind/state/OPERATIONAL-RULES.json (from template)"
  else
    qecho "  ✓ .rocketmind/state/OPERATIONAL-RULES.json (already exists — preserved)"
  fi

  # Copy hook scripts to project-local .rocketmind/hooks/
  for f in "$FRAMEWORK_DIR"/hooks/scripts/*.sh; do
    name=$(basename "$f")
    cp "$f" "$hooks_dir/$name"
    chmod +x "$hooks_dir/$name"
  done
  qecho "  ✓ .rocketmind/hooks/ (lifecycle scripts)"

  # Copy config if not present
  if [[ ! -f "$PROJECT_DIR/rocketmind.config.json" ]]; then
    cp "$FRAMEWORK_DIR/rocketmind.config.json" "$PROJECT_DIR/rocketmind.config.json"
    qecho "  ✓ rocketmind.config.json (framework configuration)"
  fi

  # Add RocketMind state dirs to .gitignore
  local gitignore="$PROJECT_DIR/.gitignore"
  if [[ -f "$gitignore" ]]; then
    if ! grep -q "\.rocketmind/errors" "$gitignore" 2>/dev/null; then
      cat >> "$gitignore" << GITIGNORE_EOF

# RocketMind
.rocketmind/errors/
.rocketmind/state/sessions.log
.rocketmind/state/tool-usage.log
.rocketmind/state/compact.log
.worktrees/
GITIGNORE_EOF
      qecho "  ✓ .gitignore (RocketMind entries added)"
    fi
  fi

  qecho "${GREEN}  ✅ Project state initialized${NC}"
}

# ─── Main ────────────────────────────────────────────────────────────────────
verify_checksums

if [[ "$INSTALL_HOOKS_ONLY" -eq 1 ]]; then
  install_git_lifecycle_hooks
  exit 0
fi

if [[ "$INSTALL_MODE" == "local" ]]; then
  init_project_state
  install_git_lifecycle_hooks
fi

case "$TOOL" in
  claude)      install_for_claude ;;
  codex)       install_for_codex ;;
  antigravity) install_for_antigravity ;;
  all)         install_for_claude; install_for_codex; install_for_antigravity ;;
esac

# ─── Summary ─────────────────────────────────────────────────────────────────
qecho ""
qecho "${BOLD}Installation complete!${NC}"
qecho ""
qecho "Installed to: ${BLUE}$CLAUDE_DIR${NC}"
qecho ""
qecho "Framework:"
qecho "  Agents:  $(ls "$FRAMEWORK_DIR/agents/"*.md 2>/dev/null | wc -l | tr -d ' ') core agents"
qecho "  Skills:  $(ls "$FRAMEWORK_DIR/skills/"*.md 2>/dev/null | wc -l | tr -d ' ') skills loaded"
qecho "  Hooks:   PreToolUse, PreCompact, Stop (PostToolUse: see rocketmind.config.json)"
qecho ""
qecho "Start with:"
qecho "  ${BLUE}/rocketmind:new-project${NC}   — start a new project from scratch"
qecho "  ${BLUE}/rocketmind:map-codebase${NC}  — analyze an existing repo before planning"
qecho "  ${BLUE}/rocketmind:resume${NC}        — continue from last session"
qecho ""
qecho "${YELLOW}Docs: https://github.com/shiprocket/rocketmind${NC}"
