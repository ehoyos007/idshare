#!/usr/bin/env bash
# Clu's session commit workflow for idshare
# Usage: ./scripts/clu-update.sh "Summary of what was done" [--no-push]

set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROGRESS_FILE="$REPO_DIR/PROGRESS.md"
PUSH=true
SUMMARY="${1:-}"
shift || true
for arg in "$@"; do [[ "$arg" == "--no-push" ]] && PUSH=false; done

if [[ -z "$SUMMARY" ]]; then
  echo "❌ Usage: ./scripts/clu-update.sh \"Summary\" [--no-push]"
  exit 1
fi

cd "$REPO_DIR"
DATE_ONLY="$(date '+%Y-%m-%d')"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M %Z')"
ENTRY="## Clu Session: $DATE_ONLY\n\n**Summary:** $SUMMARY\n\n---\n"

if [[ -f "$PROGRESS_FILE" ]]; then
  FIRST_LINE="$(head -1 "$PROGRESS_FILE")"
  REST="$(tail -n +2 "$PROGRESS_FILE")"
  printf '%s\n\n%b%s' "$FIRST_LINE" "$ENTRY" "$REST" > "$PROGRESS_FILE"
else
  printf '# Progress Log\n\n%b' "$ENTRY" > "$PROGRESS_FILE"
fi

git add -A
COMMIT_MSG="clu: $SUMMARY"
git commit -m "$COMMIT_MSG" || { echo "⚠️  Nothing to commit"; exit 0; }
echo "✅ Committed: \"$COMMIT_MSG\""

if [[ "$PUSH" == true ]]; then
  git push origin main
  echo "✅ Pushed to origin/main"
fi

echo "🟠 Done — $TIMESTAMP"
