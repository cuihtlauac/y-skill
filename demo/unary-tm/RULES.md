# Turing machine: unary successor  (n ↦ n+1)

This file is the worked TM from [`../../PROOF.md`](../../PROOF.md) §2 — the
*control* of the machine. It is both human-readable and the single source of
truth that `run.sh` parses and executes, so the "skill body" and the thing that
runs are the same text.

Alphabet: `1` and `_` (the blank). Start state `A`. Halt state `H`.
The tape is a string of cells; `head` is a 0-based index into it. If `head`
points at or past the end of the string, the scanned symbol is the blank `_`.

Transition table δ  —  `state, scanned -> write, move, next`:

    A, 1 -> 1, R, A      (walk right over the block of 1s)
    A, _ -> 1, R, H      (append one 1 and halt)
    H    -> HALT

## One step

1. Read `state`, `head`, `tape` from the configuration.
2. `scanned` = the cell at `head`, or `_` if `head` is at/past the end of `tape`.
3. If `state` is `H`: halt, change nothing.
4. Otherwise find the unique rule matching `(state, scanned)` and apply it:
   overwrite the cell at `head` with `write` (extend `tape` with the written
   symbol if `head` was past the end), move `head` by `move` (`R` = +1, `L` = -1),
   and set `state` = `next`.
5. Persist the updated `state`, `head`, `tape`.
