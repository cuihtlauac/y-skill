# Minimum test harness

Tests that the `y-skill` combinator **regenerates** a secondary skill correctly
and that the regenerated skill, when **exercised**, computes the right values.
Two gates:

- **Structural** — every child skill carries the combinator's three kept
  sections byte-for-byte (`structural.sh`). Pure text, deterministic.
- **Behavioural** — the values an exercised skill produces match a reference
  OCaml **oracle** (`oracle.ml` + `grade.sh`).

No Python: the gates are POSIX shell, the oracle is OCaml, and a `Makefile`
ties them together.

## Components

| File | Role |
|------|------|
| `oracle.ml` | Ground-truth recurrences (`g-rec`, `s-rec`, `q-rec`, `z-rec`, `collatz`, `word-rev`) plus a normal-order SK+δ normalizer for `ski-eval` (fuel-bounded, since Y-terms may diverge). `opam exec -- ocaml harness/oracle.ml <skill> <arg>` prints the value. The arg is a number for the numeric skills, a word for `word-rev`, and a space-free combinator term for `ski-eval`; output is printed as a string, so `grade.sh`'s string compare handles all three. `collatz` is not structurally decreasing (the Collatz conjecture); it terminates for every tested `n` but there is no proof it does for all. |
| `structural.sh` | Kept sections are the file's tail (from the first kept header to EOF); compares that tail to `y-skill/SKILL.md` for every child. Exits non-zero on drift. `word-rev-sub` is exempt: it is a *sibling combinator* (consult = spawn a subagent), so it rewrites the kept sections by design. |
| `grade.sh` | Reads a `<skill> <n> <got>` table (default `harness/results.txt`), compares each `got` to the oracle, exits non-zero on any mismatch — or if the table is missing or has zero cases, so an empty run cannot masquerade as a pass. |
| `results.txt` | Passing baseline for every skill (`g-rec`, `s-rec`, `q-rec`, `z-rec`, `collatz`, `word-rev`, `ski-eval`). |
| `Makefile` | `test` (both gates), `structural`, `grade`, `broken` (negative control), `clean`. |

## Running it

### Deterministic gates (cheap, repeatable)

```sh
make -C harness test      # structural + behavioural on the baseline
make -C harness broken    # negative control: injected fault MUST be rejected
```

(or `cd harness && make test`). The individual gates are also runnable directly:
`sh harness/structural.sh .` and `sh harness/grade.sh harness/results.txt`.

**These gates alone never invoke a skill.** On a fresh clone the structural
gate is *vacuous* (generated children are gitignored, and the only tracked
sibling, `word-rev-sub`, is exempt by design — the script says so in its PASS
line), and `results.txt`'s committed baselines are oracle-derived, so grading
them is a self-check of the oracle + grader plumbing. Likewise `broken` feeds
the grader hand-written wrong values: it is a negative control *of the gate*,
not a model run. Coverage of actual skill behaviour comes from the agent-driven
stage below.

### Agent-driven stage: regenerate + exercise

This is the part that actually tests the combinator. For each skill spec in
`../PROMPTS.md`, run one agent that (1) regenerates `.claude/skills/<name>/SKILL.md`
the y-skill way — new frontmatter + topic section, the three kept sections copied
verbatim from `y-skill/SKILL.md` — (2) runs `structural.sh`, and (3) exercises the
file it just wrote on a few inputs, computing **strictly by the recurrence as
written** (no outside knowledge, no "fixing"). Each agent returns one line:

```json
{"skill":"g-rec","variant":"correct","structural_pass":true,"values":[{"n":3,"got":6},{"n":4,"got":17}]}
```

Append the values to `harness/results.txt` as `<skill> <n> <got>` lines, then
`make -C harness grade`.

Include **one deliberately-broken variant** (inject a known fault, e.g. the
`−2·G(n−2)` coefficient) to confirm the harness fails as it should — that is what
`make -C harness broken` automates.

## Minimum run on record

| Variant | Regenerated recurrence | structural | exercised G(3), G(4) | oracle | behavioural |
|---------|------------------------|:----------:|----------------------|--------|:-----------:|
| correct | `3·G(n−1) − G(n−2) + 1` | PASS | 6, 17 | 6, 17 | **PASS** |
| broken  | `3·G(n−1) − 2·G(n−2) + 1` | PASS | −1, −2 | 6, 17 | **FAIL** (caught) |

The broken variant passes the structural gate (kept sections untouched) and is
caught only by the behavioural gate — which is exactly the separation we want:
structure and behaviour are independent failure modes.

## Historical limitation: worktree isolation (resolved by the repo move)

In an earlier layout `y-skill` was a *nested* git repo inside an outer repo, and
the Agent tool's `isolation: worktree` forks the **session's** git root — the
outer repo, whose worktree did **not** contain the nested `y-skill` files. The
agents fell back to writing the real `.claude/skills/<name>/SKILL.md`; in one
run the broken agent clobbered the live `g-rec`, which had to be restored by
hand.

The repo now lives at its own git root, so a worktree forks `y-skill` itself
and that failure mode no longer applies (not yet re-verified with a live
agent-driven run). If worktrees are unavailable, the fallback remains: copy
`.claude/skills/` + `harness/` into a throwaway temp dir per case, run the
agent there, and read back only the JSON.

## Deferred

Exercising a skill by **spawning one subagent per recursion frame** (the subagent
tree as an externalized stack, to push depth past a single context window) is left
for later — see the "infinite-context" discussion in the top-level TLDR.md.
