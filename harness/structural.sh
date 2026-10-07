#!/usr/bin/env sh
# Structural gate: every child skill must carry the combinator's kept sections
# byte-for-byte. They are the file's tail (from the first kept header to EOF),
# so we just compare that tail against y-skill's.
#   usage: sh harness/structural.sh [repo_root]
# Exits non-zero if any child drifted.
set -u
ROOT="${1:-.}"
SKILLS="$ROOT/.claude/skills"
MARK='# The worked example is this skill'

kept() { sed -n "/^$MARK\$/,\$p" "$1"; }

ref=$(mktemp)
kept "$SKILLS/y-skill/SKILL.md" > "$ref"
rc=0
checked=0
for d in "$SKILLS"/*/; do
  name=$(basename "$d")
  [ "$name" = y-skill ] && continue
  # word-rev-sub is a sibling combinator, not a faithful child: it deliberately
  # rewrites the kept sections (consult = spawn a subagent, not re-read).
  [ "$name" = word-rev-sub ] && continue
  [ -f "$d/SKILL.md" ] || continue
  checked=$((checked + 1))
  if kept "$d/SKILL.md" | diff -q - "$ref" >/dev/null 2>&1; then
    echo "MATCH  $name"
  else
    echo "DIFFER $name"
    rc=1
  fi
done
rm -f "$ref"
if [ "$rc" != 0 ]; then
  echo "STRUCTURAL: FAIL"
elif [ "$checked" = 0 ]; then
  # A fresh clone has no generated children (they are gitignored) and the only
  # tracked sibling, word-rev-sub, is exempt — so this pass is vacuous.
  echo "STRUCTURAL: PASS (vacuous — 0 children present; mint some via /y-skill to exercise this gate)"
else
  echo "STRUCTURAL: PASS ($checked children checked)"
fi
exit "$rc"
