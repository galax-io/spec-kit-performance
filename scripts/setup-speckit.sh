#!/usr/bin/env bash
# Setup spec-kit extensions and presets for this repo.
#
# Native extensions/presets (in the default spec-kit catalog) are installed
# via `specify ... add <id>`.  Community ones (discovery-only catalog) are
# installed from the bundled local dirs with --dev, so no internet required
# after cloning.
#
# Usage:
#   bash scripts/setup-speckit.sh         # idempotent: skip already installed
#   bash scripts/setup-speckit.sh --force # reinstall everything

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

FORCE_FLAG=""
[[ "${1:-}" == "--force" ]] && FORCE_FLAG="--force"

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

run_ext() {
  local id="$1"; shift
  local out
  if out=$(specify extension add "$@" ${FORCE_FLAG} 2>&1); then
    echo "  ✓  $id"
  elif echo "$out" | grep -q "already installed"; then
    echo "  –  $id (already installed, use --force to reinstall)"
  else
    echo "  ✗  $id"
    echo "$out"
    return 1
  fi
}

run_preset() {
  local id="$1"; shift
  local out
  if out=$(specify preset add "$@" ${FORCE_FLAG} 2>&1); then
    echo "  ✓  $id"
  elif echo "$out" | grep -q "already installed"; then
    echo "  –  $id (already installed, use --force to reinstall)"
  else
    echo "  ✗  $id"
    echo "$out"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Native extensions  (from default spec-kit catalog)
# ---------------------------------------------------------------------------
echo
echo "==> Native extensions"
run_ext agent-context  agent-context
run_ext bug            bug
run_ext git            git

# ---------------------------------------------------------------------------
# Community extensions  (bundled in .specify/extensions/, no internet needed)
# ---------------------------------------------------------------------------
echo
echo "==> Community extensions"
run_ext worktrees  ".specify/extensions/worktrees"  --dev
run_ext changelog  ".specify/extensions/changelog"  --dev
run_ext harness    ".specify/extensions/harness"    --dev
run_ext spectest   ".specify/extensions/spectest"   --dev

# ---------------------------------------------------------------------------
# Community presets  (bundled in .specify/presets/, no internet needed)
# ---------------------------------------------------------------------------
echo
echo "==> Community presets"
run_preset claude-ask-questions  claude-ask-questions  --dev ".specify/presets/claude-ask-questions"

echo
echo "Done. Run 'specify extension list' and 'specify preset list' to verify."
