# y-skill — the Y combinator as a Claude Skill

This project is an experiment: **encode the lambda-calculus Y combinator as a
Claude Agent Skill.**

## The idea

In the lambda calculus you cannot write a recursive function by name — a
nameless function has nothing to call itself *by*. The Y combinator gets
recursion anyway, through self-application: it feeds a function to itself, so
the "recursive call" is really the thing being handed a copy of itself.

    Y f = f (Y f)

A Claude Skill is a folder with a `SKILL.md` (the instructions) plus
*supporting files* the instructions open only when needed. Normally those
supporting files are separate documents. The trick here is to make a skill
whose **only supporting file is itself**:

> To consult a smaller case, read this same `SKILL.md` as if you had been
> handed only that case, and use the answer you get.

That is the Y-combinator move translated into skill form. The skill achieves
recursion with no external recursion mechanism and no second file — purely by
being applied to itself. Two rules keep the unfolding finite, exactly as a
well-founded recursion needs a base case:

1. every consultation is on a *strictly smaller* case, and
2. the smallest cases are answered directly, without consulting the file.

### `y-skill` is the fixpoint operator

`.claude/skills/y-skill/SKILL.md` is the meta-skill. Hand it a topic written
as "here are the base cases; for the rest, consult the supporting file on
smaller cases" and it writes a brand-new skill that is its own supporting
file — fixing the open recursion into a closed, self-referential one. In other
words `y-skill` plays the role of `Y`: it takes a non-recursive step
description and returns a recursive skill.

The sections that carry the self-reference (`The worked example is this
skill`, `When to consult the supporting file`, `Making a new skill on another
topic`) are copied **verbatim** into every generated skill. That word-for-word
preservation is the invariant that keeps the fixpoint intact, and it is what
the structural test below checks.

## What's in here

| Path | What it is |
|------|------------|
| `.claude/skills/y-skill/` | The meta-skill — the Y combinator itself. Invoked as `/y-skill <name> <topic>`. |
| `.claude/skills/g-rec/`   | Generated. `G(0)=2, G(1)=1, G(n)=3·G(n−1)−G(n−2)+1`. *Tree* recursion (two consultations per step). |
| `.claude/skills/s-rec/`   | Generated. `S(0)=5, S(n)=2·S(n−1)−3`. *Linear* recursion (one consultation per step). |
| `.claude/skills/hanoi-moves/` | Generated. Lists the Tower-of-Hanoi moves for *n* disks. |
| `PROMPTS.md` | The exact `/y-skill` prompt, the math recurrence, and the OCaml equivalent for each generated skill — the reference answers for testing. |
| `rec/` | An earlier standalone sketch of the same idea. |

## Installation

Skills are discovered from `.claude/skills/`. Nothing to build.

**Project-scoped (recommended).** Clone the repo and open Claude Code with
this directory as the working directory; the four skills under
`.claude/skills/` are picked up automatically and exposed as `/y-skill`,
`/g-rec`, `/s-rec`, `/hanoi-moves`.

```sh
git clone <this-repo> y-skill
cd y-skill
claude          # the skills are now available as slash commands
```

**User-scoped (available everywhere).** Copy any skill folder into your
personal skills directory:

```sh
cp -r .claude/skills/y-skill ~/.claude/skills/
```

## Testing

### 1. Behavioural — run a generated skill and check the value

Invoke a skill with a number; it unfolds by consulting itself on smaller
cases until it hits a base case, then folds the answer back up.

| Command | Expected |
|---------|----------|
| `/g-rec 4` | `17` |
| `/s-rec 6` | `131` |
| `/hanoi-moves` on 3 disks | 7 moves, ending `disk 1: A→C` |

Cross-check any value against the OCaml in `PROMPTS.md`. For example:

```ocaml
let rec s n = if n = 0 then 5 else 2 * s (n - 1) - 3  (* s 6 = 131 *)
let rec g n =
  if n = 0 then 2 else if n = 1 then 1
  else 3 * g (n - 1) - g (n - 2) + 1                  (* g 4 = 17 *)
```

Note the cost difference the recursion *shape* makes: `s-rec` is linear — one
consultation per step, a chain of length *n* — while `g-rec` branches into two
consultations per step, so the number of lookups grows exponentially (`g 4`
already fans out to 8 base-case consultations). Linear recurrences are the
cheaper, more debuggable models; see `PROMPTS.md` for the rationale and more
examples.

### 2. Structural — verify the fixpoint invariant

A generated skill is only a faithful copy of the combinator if its three
carried sections are byte-for-byte identical to the meta-skill's. This check
fails loudly if a generated skill drifted:

```sh
cd .claude/skills
python3 - <<'EOF'
import re
def sections(path):
    text = open(path).read()
    parts = re.split(r'(?m)^(# .+)$', text)
    return {parts[i].strip(): parts[i+1].strip() for i in range(1, len(parts), 2)}
keep = ["# The worked example is this skill",
        "# When to consult the supporting file",
        "# Making a new skill on another topic"]
base = sections("y-skill/SKILL.md")
ok = True
for skill in ("g-rec", "s-rec", "hanoi-moves"):
    s = sections(f"{skill}/SKILL.md")
    for k in keep:
        same = base.get(k) == s.get(k)
        ok &= same
        print(("MATCH " if same else "DIFFER"), f"{skill}", k)
print("ALL KEPT SECTIONS IDENTICAL:", ok)
EOF
```

### 3. Generate a new one

Follow a `PROMPTS.md` entry — e.g. add `q-rec` or `z-rec`:

```
/y-skill q-rec to compute Q(n) for a whole number n from 0 upwards: Q(0) = 4.
Answer that case directly. For n of 1 or more, Q(n) = Q(n - 1) + 2 * n + 1.
Do not work these values yourself, consult the supporting file once on
case n - 1, then compute the answer. Reply with number only
```

Then re-run the structural test (add the new name to the loop) and spot-check a
value against the OCaml.
