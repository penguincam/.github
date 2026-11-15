#!/usr/bin/env bash
# Proves that githooks/test.sh notices when a refusal is removed.
#
# For each refusal in the hooks and each finding in readme-check.sh, copy
# githooks/ to a scratch directory, turn that one call into a no-op, and run
# the copied test.sh. Every such copy must fail its test. The same is done
# for the two agent file scans in pre-push and for the two parts of the
# pushed range that keep held-elsewhere and overlay commits in the walk.
# Exits 1 when any copy passes.
set -euo pipefail

src="$(cd "$(dirname "$0")/../githooks" && pwd -P)"
work="$(mktemp -d "${TMPDIR:-/tmp}/penguincam-mutation.XXXXXX")"
trap 'rm -rf "$work"' EXIT

killed=0
survived=0

try() {
  # $1 file, $2 line number, $3 label
  local dir="$work/m"
  rm -rf "$dir"
  cp -R "$src" "$dir"
  sed -i.bak "$2s/^\([[:space:]]*\)\([^[:space:]]\)/\1: \2/" "$dir/$1"
  rm -f "$dir/$1.bak"
  if bash "$dir/test.sh" >/dev/null 2>&1; then
    survived=$((survived + 1))
    printf 'SURVIVED %s:%s %s\n' "$1" "$2" "$3"
  else
    killed=$((killed + 1))
    printf 'killed   %s:%s %s\n' "$1" "$2" "$3"
  fi
}

for f in commit-msg pre-push; do
  grep -nE '^[[:space:]]*pc_refuse ' "$src/$f" | while IFS=: read -r n rest; do
    printf '%s %s %s\n' "$f" "$n" "$(printf '%s' "$rest" | sed 's/^[[:space:]]*//' | cut -c1-60)"
  done
done > "$work/sites"
grep -nE '^[[:space:]]*fail "' "$src/readme-check.sh" | while IFS=: read -r n rest; do
  printf 'readme-check.sh %s %s\n' "$n" "$(printf '%s' "$rest" | sed 's/^[[:space:]]*//' | cut -c1-60)"
done >> "$work/sites"
grep -nE '^[[:space:]]*git -c core.quotePath=false (diff-tree|ls-tree) ' "$src/pre-push" | while IFS=: read -r n rest; do
  printf 'pre-push %s %s\n' "$n" "$(printf '%s' "$rest" | sed 's/^[[:space:]]*//' | cut -c1-60)"
done >> "$work/sites"

while read -r f n label; do
  try "$f" "$n" "$label"
done < "$work/sites"

try_sub() {
  # $1 file, $2 text to replace, $3 replacement, $4 label
  local dir="$work/m" content
  rm -rf "$dir"
  cp -R "$src" "$dir"
  content="$(cat "$dir/$1")"
  if [ "${content#*"$2"}" = "$content" ]; then
    survived=$((survived + 1))
    printf 'MISSING  %s %s (text not found)\n' "$1" "$4"
    return
  fi
  printf '%s\n' "${content//"$2"/"$3"}" > "$dir/$1"
  if bash "$dir/test.sh" >/dev/null 2>&1; then
    survived=$((survived + 1))
    printf 'SURVIVED %s %s\n' "$1" "$4"
  else
    killed=$((killed + 1))
    printf 'killed   %s %s\n' "$1" "$4"
  fi
}

# shellcheck disable=SC2016 # the hook source text, matched literally
try_sub pre-push '"--remotes=$remote_name"' '--remotes' "range skips commits held by any remote"
# shellcheck disable=SC2016
try_sub pre-push '"--exclude=$remote_name/$PC_OVERLAY_BRANCH" ' '' "range skips the destination's overlay branch"

printf '\nmutation-test: %s killed, %s survived\n' "$killed" "$survived"
[ "$survived" -eq 0 ]
