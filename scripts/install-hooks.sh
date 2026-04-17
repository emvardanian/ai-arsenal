#!/usr/bin/env bash
# install-hooks.sh — opt-in installer for Cycle 3 pre-commit hook that runs sync-readme.sh.
#
# Installs .git/hooks/pre-commit with a minimal wrapper that invokes scripts/sync-readme.sh
# and re-stages README.md if it was modified.
#
# Idempotent: safe to run multiple times. Will not overwrite an existing non-autosync hook.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK_DIR="$REPO_ROOT/.git/hooks"
HOOK_FILE="$HOOK_DIR/pre-commit"
SENTINEL="# task-cycle3-autosync"

if [ ! -d "$REPO_ROOT/.git" ]; then
  echo "ERROR: $REPO_ROOT is not a git repository." >&2
  exit 1
fi

mkdir -p "$HOOK_DIR"

if [ -f "$HOOK_FILE" ]; then
  if grep -qF "$SENTINEL" "$HOOK_FILE" 2>/dev/null; then
    echo "pre-commit hook already installed (idempotent skip)."
    exit 0
  fi
  echo "ERROR: $HOOK_FILE exists and is not managed by Cycle-3 autosync." >&2
  echo "Remove or rename it, then re-run install-hooks.sh." >&2
  exit 2
fi

cat > "$HOOK_FILE" <<'HOOK'
#!/usr/bin/env bash
# task-cycle3-autosync
# Runs scripts/sync-readme.sh and re-stages README.md if modified.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
SYNC="$REPO_ROOT/scripts/sync-readme.sh"

if [ ! -x "$SYNC" ]; then
  exit 0  # sync script missing or not executable; skip
fi

"$SYNC" || {
  echo "ERROR: sync-readme.sh failed; aborting commit." >&2
  exit 1
}

if ! git diff --quiet -- README.md; then
  git add README.md
  echo "autosync: README.md updated and re-staged"
fi

exit 0
HOOK

chmod +x "$HOOK_FILE"
echo "Installed $HOOK_FILE"
echo "To uninstall: rm $HOOK_FILE"
