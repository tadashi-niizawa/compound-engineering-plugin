#!/usr/bin/env bash
# Remove Compound Engineering skill symlinks from Kiro CLI's skills directory.
# Only CE-owned symlinks (those resolving under this checkout's skills/ tree)
# are removed; your own skills and other symlinks are left untouched.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_SRC="$REPO_ROOT/skills"

usage() {
  cat <<'EOF'
Usage: uninstall-skills.sh [--global | --project]

  --global    Remove CE skill links from ~/.kiro/skills/ (default)
  --project   Remove CE skill links from ./.kiro/skills/ under the current directory

Set KIRO_SKILLS_DIR to override the global destination.
EOF
  exit 1
}

SCOPE="--global"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --global | --project)
      SCOPE="$1"
      shift
      ;;
    *)
      usage
      ;;
  esac
done

if [[ "$SCOPE" == "--project" ]]; then
  DEST="$(pwd)/.kiro/skills"
else
  DEST="${KIRO_SKILLS_DIR:-$HOME/.kiro/skills}"
fi

canonical_path() {
  python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

SKILLS_ROOT_CANON="$(canonical_path "$SKILLS_SRC")"

[[ -d "$DEST" ]] || { echo "nothing to do: $DEST does not exist"; exit 0; }

removed=0
for link in "$DEST"/*; do
  [[ -L "$link" ]] || continue
  resolved="$(canonical_path "$link")"
  if [[ "$resolved" == "$SKILLS_ROOT_CANON/"* ]]; then
    rm "$link"
    echo "removed $(basename "$link")"
    removed=$((removed + 1))
  fi
done

echo "done: $removed CE skill links removed from $DEST"
