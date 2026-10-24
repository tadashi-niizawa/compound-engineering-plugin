#!/usr/bin/env bash
# Link Compound Engineering skills/ into Kiro CLI's skills discovery directory.
#
# Kiro CLI discovers skills from `skill://` resources. The default agent includes:
#   skill://.kiro/skills/*/SKILL.md     (workspace skills)
#   skill://~/.kiro/skills/*/SKILL.md   (global skills)
#
# Each skill lives in its own directory as <name>/SKILL.md with YAML frontmatter
# (name, description). CE's SKILL.md files already match this format, so this
# script just symlinks each skill directory into the Kiro skills directory.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_SRC="$REPO_ROOT/skills"

usage() {
  cat <<'EOF'
Usage: install-skills.sh [--global | --project] [--exclude-manual]

  --global          Link skills into ~/.kiro/skills/ (default)
  --project         Link skills into ./.kiro/skills/ under the current directory
  --exclude-manual  Skip manual-only skills (disable-model-invocation: true).
                    By default they ARE linked: Kiro invokes skills explicitly
                    as /skill-name slash commands, so manual-only skills are
                    safe to expose. Use this flag only if you want to keep them
                    out of the default skill-discovery glob entirely.

Set KIRO_SKILLS_DIR to override the global destination.
EOF
  exit 1
}

SCOPE="--global"
EXCLUDE_MANUAL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --global | --project)
      SCOPE="$1"
      shift
      ;;
    --exclude-manual)
      EXCLUDE_MANUAL=true
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

if [[ ! -d "$SKILLS_SRC" ]]; then
  echo "error: skills directory not found at $SKILLS_SRC" >&2
  exit 1
fi

canonical_path() {
  python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

SKILLS_ROOT_CANON="$(canonical_path "$SKILLS_SRC")"

is_ce_owned_skill_link() {
  local link_path="$1"
  [[ -L "$link_path" ]] || return 1

  local resolved
  resolved="$(canonical_path "$link_path")"
  [[ "$resolved" == "$SKILLS_ROOT_CANON/"* ]]
}

mkdir -p "$DEST"
linked=0
skipped=0
manual_omitted=0
manual_removed=0

for skill_dir in "$SKILLS_SRC"/*/; do
  [[ -f "${skill_dir}SKILL.md" ]] || continue
  name="$(basename "$skill_dir")"
  target="$DEST/$name"
  is_manual=false

  if grep -qE '^disable-model-invocation:[[:space:]]*true[[:space:]]*$' "${skill_dir}SKILL.md"; then
    is_manual=true
    if [[ "$EXCLUDE_MANUAL" == "true" ]]; then
      if is_ce_owned_skill_link "$target"; then
        rm "$target"
        echo "removed $name: CE manual-only symlink (--exclude-manual)" >&2
        manual_removed=$((manual_removed + 1))
      fi
      echo "skip $name: manual-only (disable-model-invocation)" >&2
      manual_omitted=$((manual_omitted + 1))
      continue
    fi
  fi

  if [[ -e "$target" && ! -L "$target" ]]; then
    echo "skip $name: $target exists and is not a symlink" >&2
    skipped=$((skipped + 1))
    continue
  fi

  if [[ -L "$target" ]] && ! is_ce_owned_skill_link "$target"; then
    echo "skip $name: $target is an existing user-managed symlink (not overwritten)" >&2
    skipped=$((skipped + 1))
    continue
  fi

  ln -sfn "$skill_dir" "$target"
  if [[ "$is_manual" == "true" ]]; then
    echo "linked $name (manual-only) -> $skill_dir"
  else
    echo "linked $name -> $skill_dir"
  fi
  linked=$((linked + 1))
done

echo "done: $linked linked, $skipped skipped, $manual_omitted manual-only omitted, $manual_removed stale manual-only removed (destination: $DEST)"
echo ""
echo "Start a new Kiro CLI session, then run /prompts or type /ce- and press Tab to see the skills."
