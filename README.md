# y-skill — the Y combinator as a Claude Skill

A Claude Skill is a folder with a `SKILL.md`. This repo's trick: a skill whose
**only supporting file is itself** — to handle a case, it consults its own
`SKILL.md` on a smaller case, exactly as `Y f = f (Y f)` feeds a function to
itself. Recursion with no recursion mechanism, in a Markdown file.

`y-skill` is the fixpoint operator: hand it a topic and it mints a new
self-referential skill the same way.

## Try it

```sh
git clone https://github.com/cuihtlauac/y-skill.git
cd y-skill
claude
```

Then, inside Claude Code:

| You type | You get |
|----------|---------|
| `/s-rec 6` | `131` |
| `/g-rec 4` | `17` |
| `/word-rev stressed` | `desserts` |
| `/collatz 3` | `7` |
| `/ski-eval S(K)(K)(7)` | `7` |
| `/ski-eval add(mul(2)(3))(1)` | `7` |

Watch the trace: the skill unfolds case by case, consulting its own file,
then folds the answers back up. `/ski-eval` is the deep end — a universal
evaluator (SK combinatory logic with native integers) that is itself just
another child of the combinator.

## Write your own

```
/y-skill r-rec to compute R(n) for a whole number n from 0 upwards: R(0) = 3.
Answer that case directly. For n of 1 or more, R(n) = 2 * R(n - 1) + n.
Do not work these values yourself, consult the supporting file once on
case n - 1, then compute the answer. Reply with number only
```

That is the whole programming model: say which cases are answered directly,
and how every other case is built from consultations on other cases. Then run
`/r-rec 4` and check it by hand (3, 7, 16, 35, 74…). The existing skills'
exact prompts, recurrences, and OCaml reference code are in
[`PROMPTS.md`](PROMPTS.md); `make -C harness test` checks every shipped skill
against an OCaml oracle.

## What to expect

**Correct output, delivered dead slowly, at an indecent token cost.** Every
consultation re-reads the file and reasons in context, so a linear recurrence
costs one model-step per level, a tree recurrence (`g-rec`) exponentially
many, and `/ski-eval` one per rewrite. This is the least efficient computer
you have ever used, and it is warming the planet as it recurses. That's the
point: the repo is about *what the mechanism can express*, not about speed —
the interesting things it can express include things that don't terminate at
all (`/collatz 27` is 111 levels deep and will likely die against the context
window first; see [`TLDR.md`](TLDR.md) for why, and for what would fix it).

## Is the model cheating?

The obvious objection: an LLM has seen a lot of math — maybe it just *recites*
the answer and performs the recursion theater around it. Four defenses, one
honest caveat:

1. **Non-textbook recurrences.** No factorial, no Fibonacci, no powers of two.
   `S(0)=5, S(n)=2·S(n−1)−3` has no Wikipedia page; its values aren't in the
   training data to recite.
2. **The trace is auditable.** The unfolding is visible step by step — you can
   check each consultation applied the rule, not just the final number.
3. **An oracle grades it.** `make -C harness test` compares exercised values
   against a deterministic OCaml implementation (`harness/oracle.ml`).
4. **The broken-variant test** — the sharpest one. Inject a deliberately wrong
   coefficient into a skill and the model produces *faithfully wrong* values
   (the buggy `g-rec` yields −1, −2 where the true values are 6, 17). A model
   that recited from knowledge would "helpfully" return the correct sequence;
   following a wrong rule off a cliff is exactly what honest rule-following
   looks like. `make -C harness broken` automates the check.

The caveat: none of this *eliminates* shortcutting — a small or famous case
may still be answered from memory, and fidelity drifts as chains get deep.
The checks bound the cheating; they don't abolish it. The strongest
anti-recitation artifact in the repo is the [`ski-eval`](PROMPTS.md#ski-eval)
flagship: `s-rec` compiled to combinators,
`Y(B(S(C(B(cond)(C(eq)(0)))(5)))(…))(6)`, whose value `131` no model recites —
it can only be computed by actually rewriting, and the oracle agrees with the
result.

## Where everything else is

| Doc | What's in it |
|-----|--------------|
| [`TLDR.md`](TLDR.md) | The long version: the idea in full, the infinite-context idealization and its gap (LBA vs TM, the disk trampoline), the subagent experiment that didn't pan out, related work. |
| [`PROOF.md`](PROOF.md) | Is this Turing complete? Two constructions (native SK evaluation; TM simulation on an external tape), held to the *Surprisingly Turing-Complete* catalog's standards. |
| [`PROMPTS.md`](PROMPTS.md) | Every generated skill's defining prompt, recurrence, and OCaml reference. |
| [`harness/`](harness/README.md) | The test harness: structural gate (fixpoint invariant) + behavioural gate (oracle). |
| [`demo/unary-tm/`](demo/unary-tm/README.md) | A Turing machine run as a skill, one command. |

## License

[MIT](LICENSE) © 2026 Cuihtlauac Alvarado.
