# CLAUDE.md

The Y combinator as a Claude Skill: `.claude/skills/y-skill/SKILL.md` is a
self-referential skill (its only supporting file is itself) that mints further
self-referential skills. Written under the **infinite-context hypothesis** —
chains of self-consultations may be unbounded; termination belongs to the
topic, not the combinator.

## Commands

```sh
make -C harness test      # structural gate + behavioural gate (run before committing)
make -C harness broken    # negative control: injected faults MUST be rejected
opam exec -- ocaml harness/oracle.ml <skill> <arg>   # ground truth for one case
sh demo/unary-tm/run.sh 3                            # the TM demo
```

OCaml runs through `opam exec --` only (see the user-level `ocaml` skill rule).

## Invariants

- **Kept sections are byte-identical.** Every generated skill's tail — from the
  line `# The worked example is this skill` to EOF — must match
  `y-skill/SKILL.md` exactly. `harness/structural.sh` enforces it. The only
  exemption is `word-rev-sub`, a deliberate *sibling* combinator (consult =
  spawn a subagent) excluded by name in `structural.sh`.
- **Generated skills are gitignored**, not committed: they are reproducible via
  `/y-skill`. Only the `y-skill` meta-skill itself (and the hand-written
  `word-rev-sub`) are tracked under `.claude/skills/`.
- **The oracle is ground truth.** `harness/results.txt` baselines must come
  from `harness/oracle.ml`, never computed by the model. One `<skill> <arg>
  <got>` per line; the arg and got must be space-free tokens.
- The behavioural gate compares strings, so non-numeric outputs (words,
  combinator terms) need no special handling.

## Adding a generated skill

1. Copy an existing child (e.g. `g-rec/SKILL.md`) into
   `.claude/skills/<name>/` and patch **only** the frontmatter and the topic
   section at the top — never touch the kept tail.
2. Gitignore `.claude/skills/<name>/`.
3. Add the recurrence to `harness/oracle.ml`, oracle-verified baselines to
   `harness/results.txt`, and one wrong value to the `broken` target in
   `harness/Makefile`.
4. Document it: a section in `PROMPTS.md` (defining prompt, recurrence, OCaml)
   and a row in `TLDR.md`'s skills table; mention in `README.md` only if it
   changes the quick start.
5. `make -C harness test && make -C harness broken`.

## Doc map

- `README.md` — short, code-first intro ("try it", cost warning, "is the model
  cheating?"). Keep it short; depth goes elsewhere.
- `TLDR.md` — the long version: theory, the infinite-context gap (finite
  context vs TM, disk trampoline), the subagent negative result, related work.
- `PROOF.md` — Turing-completeness constructions (native SK; finite-regime TM).
- `PROMPTS.md` — per-skill specs: prompt, recurrence, OCaml reference.
- `harness/README.md` — gates, components, known limitations.
- `demo/unary-tm/` — runnable TM-as-a-skill exhibit.
