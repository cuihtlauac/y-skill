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
being applied to itself.

**The combinator is written under the infinite-context hypothesis.** The real Y
combinator gives a fixpoint but *no* termination guarantee, and this skill is
faithful to that: it assumes the context window is an unbounded tape, so a chain
of consultations may run arbitrarily deep, and nothing forces it to stop. Only
two things bound the unfolding, and only the first is guaranteed:

1. some cases are answered directly, without consulting the file — the only
   places a chain can stop; and
2. *when* the topic's instructions always move toward such a case, the
   recursion is finite. When they do not, it runs without end — permitted, not
   an error, under the infinite-context assumption.

So termination is a property of the **topic**, not of the combinator.
Well-founded topics (every consultation strictly smaller) always halt;
general-recursion topics (e.g. Collatz, whose odd step `3n+1` grows) may not.
The gap between this idealization and a real, finite context is documented at
the end of this file.

### `y-skill` is the fixpoint operator

`.claude/skills/y-skill/SKILL.md` is the meta-skill. Hand it a topic written
as "here are the cases answered directly; for the rest, consult the supporting
file on other cases" and it writes a brand-new skill that is its own supporting
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
| `.claude/skills/y-skill/` | The meta-skill — the Y combinator itself, written under the **infinite-context hypothesis**. Invoked as `/y-skill <name> <topic>`. |
| `.claude/skills/g-rec/`   | Generated. `G(0)=2, G(1)=1, G(n)=3·G(n−1)−G(n−2)+1`. *Tree* recursion (two consultations per step); terminates (well-founded topic). |
| `.claude/skills/s-rec/`   | Generated. `S(0)=5, S(n)=2·S(n−1)−3`. *Linear* recursion (one consultation per step); terminates (well-founded topic). |
| `.claude/skills/q-rec/`   | Generated. `Q(0)=4, Q(n)=Q(n−1)+2n+1`. *Linear* recursion whose step depends on the index `n`; terminates (well-founded topic). |
| `.claude/skills/z-rec/`   | Generated. `Z(0)=1, Z(n)=n−2·Z(n−1)`. *Linear* recursion; sign flips every step (good for spotting a dropped minus); terminates (well-founded topic). |
| `.claude/skills/word-rev/`| Generated. **Non-numeric.** Reverses a word: `rev("")=""`, `rev(x·s)=rev(s)·x`. *Linear structural* recursion — the shrinking case is a shorter *word*, not a number; terminates (well-founded on length). Shows the combinator isn't intrinsically about numbers. |
| `.claude/skills/collatz/` | Generated. Collatz stopping time `T(1)=0; T(n)=1+T(n/2)` if even, `1+T(3n+1)` if odd. *General* recursion — no well-founded measure, so it may not terminate. The case the infinite-context combinator exists for. |
| `PROMPTS.md` | The exact `/y-skill` prompt, the math recurrence, and the OCaml equivalent for each generated skill — the reference answers for testing. |
| `rec/` | An earlier standalone sketch of the same idea. |

## Installation

Skills are discovered from `.claude/skills/`. Nothing to build.

**Project-scoped (recommended).** Clone the repo and open Claude Code with
this directory as the working directory; the skills under
`.claude/skills/` are picked up automatically and exposed as `/y-skill`,
`/g-rec`, `/s-rec`, `/q-rec`, `/z-rec`, `/word-rev`, `/collatz`.

```sh
git clone https://github.com/cuihtlauac/y-skill.git
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
| `/q-rec 5` | `39` |
| `/z-rec 5` | `-23` |
| `/word-rev stressed` | `desserts` |
| `/collatz 3` | `7` |
| `/collatz 27` | `111` (but 111 deep — expect it to hit a context or loop limit; see the gap section) |

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
carried sections are byte-for-byte identical to the meta-skill's. Those sections
are the file's *tail* (from the first kept header to EOF), so the check is just
"extract the tail, `diff` it against y-skill" — no parsing:

```sh
# from the repo root
ref=$(mktemp)
sed -n '/^# The worked example is this skill$/,$p' .claude/skills/y-skill/SKILL.md > "$ref"
for s in g-rec s-rec q-rec z-rec word-rev collatz; do
  sed -n '/^# The worked example is this skill$/,$p' ".claude/skills/$s/SKILL.md" \
    | diff -q - "$ref" >/dev/null && echo "MATCH  $s" || echo "DIFFER $s"
done
rm -f "$ref"
```

This is exactly what `harness/structural.sh` automates — run it with
`make -C harness structural`.

Note `collatz` is included and passes: because the combinator now carries the
infinite-context discipline, `collatz` is a *faithful* child — it keeps the
three sections verbatim. What makes it general recursion lives entirely in its
own topic section (`How to compute T(n)`, where the `3n+1` step grows), not in
the carried machinery. Under the old finite framing `collatz` had to break the
invariant; under the infinite-context combinator it no longer does.

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

## The infinite-context idealization and the gap

The combinator itself — `y-skill` — is written **as if the context window were
an infinite tape**, and that choice flows to every skill it mints. Its
`When to consult the supporting file` section no longer promises finiteness; it
says a chain of consultations stays in context, stacked without bound, and stops
only at a directly-answered case. So the combinator is the honest Y: a fixpoint
operator with *no* termination guarantee.

Termination is pushed down to each **topic**. A topic with a well-founded
measure — every consultation strictly smaller, whether that is a smaller
number (`g-rec`, `s-rec`, `q-rec`, `z-rec`) or a shorter word (`word-rev`)
— always bottoms out; that is the μ (least-fixpoint / inductive) special case,
termination for free. A topic without one — `collatz`, whose odd step `3n+1`
grows — is general recursion and need not halt. Both are *faithful* children:
they carry the same infinite-context machinery verbatim, and differ only in
whether their own topic section happens to supply a descent.

### What the infinite-context combinator assumes

Recursion is purely in-context self-consultation — no disk, no trampoline, no
bound on depth. With the strictly-smaller guard gone from the combinator, a
topic like `collatz` (for odd `n` the next case `3n+1` is *larger*) is free to
run forever. Under the assumption that context is unbounded, this is legitimate
and genuinely powerful:

- the context *is* an unbounded tape, so the construction is Turing-complete;
- because the well-founded guard is gone, it is **general recursion**, and it
  inherits real non-termination. Whether `/collatz n` ever returns is the
  Collatz conjecture (open since 1937). This is exactly the "when to consult"
  joke made into a running artifact: the skill really can fail to halt, and
  deciding whether it will, in general, *is* the halting problem.

### The gap: a real context is finite

In any real deployment the context window is a **fixed finite cap**. Each
consultation re-injects the whole `SKILL.md` plus the model's reasoning, and
nothing is ever freed, so the recursion's stack space *is* the context. A
device whose entire working memory is a fixed finite size that it re-reads in
full each step is, formally, a **linear bounded automaton** — it decides the
context-sensitive languages, strictly weaker than a Turing machine. Depth is
capped at roughly `context ÷ cost-per-frame` (a few hundred to low thousands).
So run as-is, `collatz` is a *bounded-memory approximation* of the infinite
object it describes: `/collatz 3` (depth 7) is fine, `/collatz 27` (depth 111)
will likely wall out against the context or a harness loop limit.

### Closing the gap: the disk trampoline

To recover the idealized behaviour you convert the stack recursion into a
**trampoline with the stack stored externally**:

- a state file (e.g. `rec/stack.json`) holds the pending frames plus an
  accumulator;
- each invocation does *one* step — pop a frame; base case folds its value into
  the parent, otherwise push the next case — then writes the file back and
  re-invokes, carrying nothing;
- the context is compacted (or fresh) between steps, so the model holds only
  **one frame** at a time;
- a background driver (or the `/loop` skill) re-invokes until the stack empties.

This recreates the Turing-machine separation: **bounded finite control**
(re-read each step) plus an **unbounded tape** (the stack file, of which only
the top is touched per step). Depth now costs disk, not context.

### Is the trampoline a computability requirement or just a safety measure?

Both — and which one depends precisely on whether you treat the context as
finite:

- **Relative to a fixed finite context (reality): it is a computability
  requirement.** It is the step that promotes the system from a linear bounded
  automaton to a Turing machine. Without an external store there are total,
  well-defined recursions you simply cannot run to completion, because their
  working memory exceeds the window.
- **Relative to an idealized unbounded-growing context (what `collatz`
  assumes): it is merely a safety / efficiency measure.** The context could
  itself serve as the tape, so the trampoline is not needed for computability;
  it only avoids the hard cap, the `O(depth²)` cost of re-reading an `O(depth)`
  transcript on every step, and the reliability decay of attending over a huge
  context. All complexity and engineering, not computability.

Two caveats keep this honest. "Disk" is **incidental**: any unbounded store
accessed through bounded local windows works (a file, a database, state threaded
through prompts). The real requirement is the *separation of bounded control
from unbounded tape* — which is also, not coincidentally, what keeps the context
small. That coincidence is why the same move looks like a mere safety measure
yet is secretly load-bearing for computability under a finite budget.

### Practical ceilings you hit first

Even with the trampoline, the limits you actually meet are empirical, roughly in
order:

1. **Model fidelity** — the model must execute the pop/push protocol perfectly
   every step; drift accumulates with depth, so reliability, not theory, is the
   real bound.
2. **Harness guards** — Claude Code may cap tool-call loops or recursion depth.
3. **Cost and wall-clock** — every step is a full model turn.
4. **No native return** — there is no call stack, so the state file *is* the
   entire return mechanism; it is the part most likely to go wrong.

## Related work / prior art

The neighbourhood is crowded — recursion in LLM skills and agents, "Y combinator
for LLMs", and self-improving meta-skills all exist — but the specific
construction here (a `SKILL.md` that is its own supporting file, recursing
through the skill-loading mechanism itself) does not appear to be a documented
pattern. The nearest work, and how it differs:

| Work | What it does | How it differs from this project |
|------|--------------|----------------------------------|
| [The Y-Combinator for LLMs / λ-RLM](https://arxiv.org/abs/2603.20105) (Roy) | Externalizes the prompt into a REPL and runs a *deterministic* combinator chain (Split/Map/Filter/Reduce); the LLM is used only at the leaves. | Closest on the name and the fixed-point analogy, but opposite intent: it uses Y to **bound** depth (`d = ⌈log_k(n/τ)⌉`) and *guarantee* termination for long-context work. No self-referential skill file; the recursion lives in a symbolic executor, not in the skill format. |
| [`rawwerks/ypi`](https://github.com/rawwerks/ypi) | A recursive coding agent "inspired by RLMs" — an LLM that calls itself. | Agent-level self-calls, not a skill that is its own supporting file. |
| [`recursive-decomposition-skill`](https://github.com/massimodeluisa/recursive-decomposition-skill) (de Luisa) | A real Claude Code skill; handles long context by **spawning sub-agents** (batches, *depth 1 only*, sub-agents don't recurse). | Recursion = sub-agent fan-out, not self-reading. No Y combinator, no lambda calculus; "recursive" names the decomposition strategy. |
| [`singularity-claude`](https://github.com/Shmayro/singularity-claude), [`recursive-improve`](https://github.com/kayba-ai/recursive-improve); research: STOP, Ladder | Skills/agents that **score and rewrite themselves** across improvement loops. | A different sense of "recursive": meta-level self-*modification*, not a fixpoint over inputs. |

**What appears to be original here:** recursion carried *inside the skill-loading
mechanism* — a single `SKILL.md` whose only supporting file is itself, re-read on
a smaller case with no sub-agents, no REPL, no code generation, and no external
combinator executor (the context *is* the tape); a meta-skill (`y-skill`) that is
literally the fixpoint operator, minting self-referential skills by copying its
carried sections verbatim; and the framing as a quine-like object (ν for the
self-containing artifact, μ for each terminating run) written under the
infinite-context hypothesis.

*Caveat: a negative search result is not proof. Something this small could live
in an un-indexed gist or blog post; this is "not a known pattern", not "provably
first". Searched October 2026.*

## License

[MIT](LICENSE) © 2026 Cuihtlauac Alvarado.
