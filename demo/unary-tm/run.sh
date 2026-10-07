#!/usr/bin/env sh
# Deterministic driver for the unary-successor Turing machine whose transition
# table lives in RULES.md (the "skill body"). Bounded finite control (the table,
# re-consulted each step) over an unbounded tape (here an in-memory string that
# grows without a cap) — the LBA->TM architecture of PROOF.md, run mechanically.
#
#   usage: sh run.sh [n]      n = unary input (number of 1s), default 3
#
# Prints the full step trace and halts with the successor in unary. The driver
# itself makes no decision beyond "state == H ? stop" — it provides no
# computational power; the control is entirely in RULES.md.
set -u
HERE=$(dirname "$0")
RULES="$HERE/RULES.md"
HALT=H
n=${1:-3}

# Initial configuration: tape = n ones, head at the left, start state A.
tape=$(printf '%*s' "$n" '' | tr ' ' '1')
state=A
head=0
step=0

# The machine-readable table, extracted from RULES.md: each rule line
# "A, 1 -> 1, R, A" becomes the tuple "A 1 1 R A". This is the single source of
# truth — the driver executes exactly what the document states.
rules=$(sed -n 's/^[[:space:]]*\([A-Z]\), \(.\) -> \(.\), \([LR]\), \([A-Z]\).*/\1 \2 \3 \4 \5/p' "$RULES")

printf 'start   state=%s head=%s tape=%s\n' "$state" "$head" "${tape:-_}"
while [ "$state" != "$HALT" ]; do
  len=$(printf '%s' "$tape" | wc -c)
  if [ "$head" -ge "$len" ]; then
    scanned=_
  else
    scanned=$(printf '%s' "$tape" | cut -c $((head + 1)))
  fi

  rule=$(printf '%s\n' "$rules" | awk -v s="$state" -v c="$scanned" '$1==s && $2==c {print; exit}')
  [ -n "$rule" ] || { echo "no rule for ($state, $scanned)"; exit 1; }
  w=$(echo "$rule" | cut -d' ' -f3)
  mv=$(echo "$rule" | cut -d' ' -f4)
  nx=$(echo "$rule" | cut -d' ' -f5)

  if [ "$head" -ge "$len" ]; then
    tape="${tape}${w}"                               # past the end: extend
  else
    if [ "$head" -eq 0 ]; then pre=""; else pre=$(printf '%s' "$tape" | cut -c 1-"$head"); fi
    post=$(printf '%s' "$tape" | cut -c $((head + 2))-)
    tape="${pre}${w}${post}"
  fi
  if [ "$mv" = R ]; then head=$((head + 1)); else head=$((head - 1)); fi
  state=$nx
  step=$((step + 1))
  printf 'step %-2s %s,%s -> %s,%s,%s   state=%s head=%s tape=%s\n' \
    "$step" "$(echo "$rule" | cut -d' ' -f1)" "$scanned" "$w" "$mv" "$nx" \
    "$state" "$head" "$tape"
done

ones=$(printf '%s' "$tape" | tr -cd 1 | wc -c)
printf 'HALT after %s steps: tape=%s = unary %s  (successor of %s)\n' \
  "$step" "$tape" "$ones" "$n"
