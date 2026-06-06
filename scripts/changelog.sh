#!/bin/bash
# Generate categorized release notes between two refs.
#
# Usage:
#   scripts/changelog.sh <prev_ref> <head_ref> [repo_url]
#
# - <prev_ref>  may be empty; if so, use the most recent v* tag, or the
#               last 30 commits when no tag exists.
# - <head_ref>  defaults to HEAD.
# - <repo_url>  optional, for short-sha links. Falls back to the
#               GITHUB_SERVER_URL/GITHUB_REPOSITORY env vars used by
#               GitHub Actions, then to no-link mode.
#
# Output goes to stdout in markdown.

set -euo pipefail

prev_ref="${1:-}"
head_ref="${2:-HEAD}"
repo_url="${3:-}"

if [ -z "$repo_url" ] && [ -n "${GITHUB_SERVER_URL:-}" ] && [ -n "${GITHUB_REPOSITORY:-}" ]; then
  repo_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}"
fi

if [ -z "$prev_ref" ]; then
  prev_ref=$(git tag --list 'v*' --sort=-v:refname | head -n1 || true)
fi

if [ -n "$prev_ref" ] && git rev-parse --verify "$prev_ref" >/dev/null 2>&1; then
  range="${prev_ref}..${head_ref}"
  range_label="自 ${prev_ref} 起"
else
  range="$head_ref"
  range_label="近期"
  prev_ref=""
fi

# Collect commits: skip merge commits, subject only.
# Format on each line: <short-sha>\x1f<subject>
# Use a portable read loop since macOS still ships bash 3.2 without mapfile.
commits=()
while IFS= read -r line; do
  commits+=("$line")
done < <(
  git log "$range" \
    --no-merges \
    --pretty=format:'%h%x1f%s' \
    | head -n 200
)

declare -a feat=() fix=() refactor=() perf=() ci=() test=() other=()

for line in "${commits[@]}"; do
  sha="${line%%$'\x1f'*}"
  subject="${line#*$'\x1f'}"

  # Build linked entry.
  if [ -n "$repo_url" ]; then
    entry="- ${subject} ([\`${sha}\`](${repo_url}/commit/${sha}))"
  else
    entry="- ${subject} (\`${sha}\`)"
  fi

  prefix="${subject%%:*}"
  # Strip an optional scope, e.g. "feat(adb)" -> "feat".
  prefix="${prefix%%(*}"

  case "$prefix" in
    feat)            feat+=("$entry") ;;
    fix)             fix+=("$entry") ;;
    refactor)        refactor+=("$entry") ;;
    perf)            perf+=("$entry") ;;
    ci|build)        ci+=("$entry") ;;
    test)            test+=("$entry") ;;
    docs|chore|style) ;;  # Intentionally filtered out of release notes.
    *)               other+=("$entry") ;;
  esac
done

emit_section() {
  local title="$1"
  shift
  if [ "$#" -gt 0 ]; then
    echo "### $title"
    printf '%s\n' "$@"
    echo
  fi
}

# Helper: expand a possibly-empty array safely under bash 3.2 + set -u.
# Usage: emit_section "title" $(expand_array name_of_array)
# but printf won't take an empty list, so route through emit_section directly:
section() {
  local title="$1"
  local -a items=()
  if [ "$2" = "--" ]; then
    shift 2
    items=("$@")
  fi
  emit_section "$title" "${items[@]+"${items[@]}"}"
}

if [ -n "$prev_ref" ]; then
  echo "**${range_label}的更新**"
else
  echo "**${range_label}的更新**（无可用上一标签）"
fi
echo

section "🚀 新功能"      -- "${feat[@]+"${feat[@]}"}"
section "🐛 问题修复"    -- "${fix[@]+"${fix[@]}"}"
section "⚡ 性能优化"    -- "${perf[@]+"${perf[@]}"}"
section "🔧 代码重构"    -- "${refactor[@]+"${refactor[@]}"}"
section "📦 工程化"      -- "${ci[@]+"${ci[@]}"}"
section "🧪 测试"        -- "${test[@]+"${test[@]}"}"
section "📝 其他变更"    -- "${other[@]+"${other[@]}"}"

total=$(( ${#feat[@]} + ${#fix[@]} + ${#refactor[@]} + ${#perf[@]} + ${#ci[@]} + ${#test[@]} + ${#other[@]} ))
if [ "$total" -eq 0 ]; then
  echo "_仅文档或日常维护变更，无功能性更新。_"
fi
