# Demo: a Turing machine, run as a skill

This is the worked construction of [`../../PROOF.md`](../../PROOF.md) §2, made
runnable: the **unary-successor Turing machine** (`n ↦ n+1`), with its transition
table as the *control* and the tape as an *external store*, driven one step at a
time until it halts.

- [`RULES.md`](RULES.md) — the transition table δ (the "skill body"). Human- and
  LLM-readable, and the single source of truth the driver parses.
- [`run.sh`](run.sh) — a POSIX-shell driver that executes it deterministically.

## Deterministic reproduction (one command)

```sh
sh demo/unary-tm/run.sh 3      # or any n; default 3
```

Output:

```
start   state=A head=0 tape=111
step 1  A,1 -> 1,R,A   state=A head=1 tape=111
step 2  A,1 -> 1,R,A   state=A head=2 tape=111
step 3  A,1 -> 1,R,A   state=A head=3 tape=111
step 4  A,_ -> 1,R,H   state=H head=4 tape=1111
HALT after 4 steps: tape=1111 = unary 4  (successor of 3)
```

`run.sh` parses the rule lines straight out of `RULES.md`, so it executes exactly
what the document states — bounded finite control (the table, re-consulted each
step) over an unbounded tape (a string that grows without a cap). The driver
decides nothing but "state == H ? stop"; all the computation is in `RULES.md`.
This is the mechanical, parser-executable interpreter of PROOF.md §3 — proof that
the step function needs no intelligence, only faithful rule-following.

## LLM-as-CPU mode (the live demo)

The same machine was run with **Claude as the interpreter**: a dumb driver loop
re-invoked a *fresh subagent per step*, whose entire context was `RULES.md` plus
a `config.txt` tape file — it never saw the history, it re-read the tape each
step. That is the trampoline from TLDR.md's gap section: bounded control
re-read each step, unbounded tape outside, context compacted (here, discarded)
between steps.

Tape store `config.txt`:

```
state: A
head: 0
tape: 111
```

Per-step subagent prompt (the "clock"; it does no computation itself):

> You are the CPU for ONE step of a Turing machine. Do exactly one step, no more.
> Read the transition table at RULES.md and the configuration at config.txt,
> perform exactly one step per the "One step" procedure, write the updated
> `state:`/`head:`/`tape:` back to config.txt, and report NEW_STATE / NEW_HEAD /
> NEW_TAPE / HALTED.

Running that four times reproduced the deterministic trace exactly, halting with
`tape: 1111` and `state: H`. Two independent interpreters — a neural net and ~40
lines of shell — executing the *same* table to the *same* result is the point of
PROOF.md §3: Turing completeness lives in the notation, not in the CPU.

## Why this is here

The `PROOF.md` construction is a general reduction (any TM → a skill). This demo
is the catalog-style *implementation exhibit* that accompanies it: the
construction doesn't just typecheck on paper, it runs — and the tape visibly
grows past its starting length (`111` → `1111`) while each step holds only O(1)
state, which is exactly the LBA→TM separation the proof turns on.
