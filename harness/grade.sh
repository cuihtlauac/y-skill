#!/usr/bin/env sh
# Behavioural gate: compare exercised values against the OCaml oracle.
# Input is a whitespace-separated table "<skill> <n> <got>", one per line
# (blank lines and lines starting with # are ignored).
#   usage: sh harness/grade.sh [results.txt]
# Exits non-zero if any case disagrees with the oracle.
set -u
HERE=$(dirname "$0")
RES="${1:-$HERE/results.txt}"
if [ ! -f "$RES" ]; then
  echo "ERROR: results file not found: $RES"
  echo "BEHAVIOURAL: FAIL"
  exit 1
fi
rc=0
cases=0
while read -r skill n got rest; do
  [ -z "${skill:-}" ] && continue
  case "$skill" in \#*) continue ;; esac
  cases=$((cases + 1))
  want=$(opam exec -- ocaml "$HERE/oracle.ml" "$skill" "$n") || { echo "ERROR oracle $skill $n"; rc=1; continue; }
  if [ "$got" = "$want" ]; then
    echo "PASS  $skill($n)  got=$got  oracle=$want"
  else
    echo "FAIL  $skill($n)  got=$got  oracle=$want"
    rc=1
  fi
done < "$RES"
if [ "$cases" = 0 ]; then
  echo "ERROR: no cases in $RES — an empty gate proves nothing"
  rc=1
fi
[ "$rc" = 0 ] && echo "BEHAVIOURAL: PASS ($cases cases)" || echo "BEHAVIOURAL: FAIL"
exit "$rc"
