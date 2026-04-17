#!/usr/bin/env bash
# sync-readme.sh — regenerate README.md AUTOSYNC regions from authoritative sources.
#
# Sources:
#   skills/task/SKILL.md          -- Agent Reference table
#   skills/task/agents/refs/model-tiers.md
#   skills/task/agents/refs/scope-pipelines.md
#   skills/task/agents/refs/pipelines.md
#
# Autosync regions in README.md (bounded by HTML comments):
#   <!-- AUTOSYNC:BEGIN:agent-count -->      agent count sentence
#   <!-- AUTOSYNC:BEGIN:agent-table -->      agent table
#   <!-- AUTOSYNC:BEGIN:scope-summary -->    scope-family summary table
#   <!-- AUTOSYNC:BEGIN:pipeline-diagram --> pipeline ASCII
#
# Exit codes:
#   0  success (README updated or already in sync)
#   1  parse error in a source file
#   2  source file missing
#   3  cannot locate target section for initial marker insertion

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_MD="$REPO_ROOT/skills/task/SKILL.md"
MODEL_TIERS="$REPO_ROOT/skills/task/agents/refs/model-tiers.md"
SCOPE_PIPELINES="$REPO_ROOT/skills/task/agents/refs/scope-pipelines.md"
PIPELINES="$REPO_ROOT/skills/task/agents/refs/pipelines.md"
README="$REPO_ROOT/README.md"

# Check source files
for f in "$SKILL_MD" "$MODEL_TIERS" "$SCOPE_PIPELINES" "$PIPELINES" "$README"; do
  if [ ! -f "$f" ]; then
    echo "ERROR: required file missing: $f" >&2
    exit 2
  fi
done

# Extract agent count from SKILL.md Agent Reference table.
# Table rows start with "| " and the first cell is either a number or stage number like 5.5 / 8.5 / 9.5.
generate_agent_count() {
  local count
  count=$(awk '
    /^## Agent Reference/ { in_section=1; next }
    /^## / && !/^## Agent Reference/ { in_section=0 }
    in_section && /^\| [0-9]/ { count++ }
    END { print count+0 }
  ' "$SKILL_MD")

  if [ "$count" -lt 1 ]; then
    echo "ERROR: could not count agent rows in SKILL.md" >&2
    exit 1
  fi

  cat <<EOF
The centerpiece is the **Task** skill — a scope-adaptive orchestrator that runs up to ${count} specialized agents through a complete development lifecycle, with per-module Reviewer-Lite, optional delegation to the \`superpowers\` plugin, and daily-UX slash commands.
EOF
}

# Extract agent table from SKILL.md (between ## Agent Reference and next ## or **Model strategy**).
generate_agent_table() {
  awk '
    /^## Agent Reference/ { in_section=1; next }
    /^## / && !/^## Agent Reference/ { in_section=0 }
    /^\*\*Model strategy/ { in_section=0 }
    in_section && (/^\| / || /^$/) { print }
  ' "$SKILL_MD" | sed '/^$/d'
}

# Extract scope-family summary from refs/pipelines.md ## Adaptive Pipeline section.
generate_scope_summary() {
  awk '
    /^## Adaptive Pipeline/ { in_section=1; next }
    /^## / && !/^## Adaptive Pipeline/ { in_section=0 }
    in_section && (/^\| / || /^\*\*/) { print }
  ' "$PIPELINES" | sed '/^$/d' | head -30
}

# Extract pipeline diagram from refs/pipelines.md ## Pipeline Overview ```...``` block.
generate_pipeline_diagram() {
  awk '
    /^## Pipeline Overview/ { in_section=1; next }
    /^## / && !/^## Pipeline Overview/ { in_section=0 }
    in_section && /^```/ { in_code = !in_code; print; next }
    in_section && in_code { print }
  ' "$PIPELINES"
}

# Replace AUTOSYNC region in README with generated content.
# Usage: replace_region <region-name> <generated-content>
replace_region() {
  local region="$1"
  local content="$2"
  local begin_marker="<!-- AUTOSYNC:BEGIN:${region} -->"
  local end_marker="<!-- AUTOSYNC:END -->"

  if ! grep -qF "$begin_marker" "$README"; then
    echo "WARN: region '${region}' marker not found in README; skipping. Add <!-- AUTOSYNC:BEGIN:${region} --> ... <!-- AUTOSYNC:END --> manually first." >&2
    return 0
  fi

  local tmp
  tmp=$(mktemp)
  awk -v region="$region" -v content="$content" '
    BEGIN { inside = 0 }
    $0 ~ ("<!-- AUTOSYNC:BEGIN:" region " -->") {
      print
      print content
      inside = 1
      next
    }
    inside && /<!-- AUTOSYNC:END -->/ {
      inside = 0
      print
      next
    }
    !inside { print }
  ' "$README" > "$tmp"

  mv "$tmp" "$README"
}

echo "Syncing README.md from skills/task/ authoritative sources..."

AGENT_COUNT_CONTENT=$(generate_agent_count)
AGENT_TABLE_CONTENT=$(generate_agent_table)
SCOPE_SUMMARY_CONTENT=$(generate_scope_summary)
PIPELINE_DIAGRAM_CONTENT=$(generate_pipeline_diagram)

replace_region "agent-count" "$AGENT_COUNT_CONTENT"
replace_region "agent-table" "$AGENT_TABLE_CONTENT"
replace_region "scope-summary" "$SCOPE_SUMMARY_CONTENT"
replace_region "pipeline-diagram" "$PIPELINE_DIAGRAM_CONTENT"

echo "Done. Review README.md diff."
