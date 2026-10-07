# Is y-skill Turing complete? Two constructions

This note upgrades the hand-wave ("look, a Y combinator and a non-terminating
recurrence") into the kind of argument the
[*Surprisingly Turing-Complete*](https://gwern.net/turing-complete) catalog
accepts: a **general reduction** from a known-universal model, made **fully
mechanical**, with every idealization **stated** and **matched** to the ones that
catalog already grants its entries.

There are two constructions, one per idealization regime:

1. **The native regime** (§2). Under the **infinite-context hypothesis** — the
   combinator's own declared semantics — a generated child of `y-skill`
   normalizes terms of SK combinatory logic, a known-universal model, by pure
   self-consultation. Turing completeness with *no external machinery at all*:
   no store, no driver, no tape file. The consultation chain is the machine.
2. **The finite regime** (§3). Refusing that idealization, an external unbounded
   store plus a dumb re-invocation driver recover Turing power from a finite
   context: a general simulation of an arbitrary Turing machine. This is the
   construction that speaks to physical reality (the LBA→TM promotion).

Both rest on one shared assumption — a **faithful interpreter** — examined in §4.

## 1. The idealizations, and that they match the catalog

Turing completeness is *always* a statement about an idealized model, never about
a physical device (your laptop has finite RAM and is, strictly, a finite-state
machine). Each idealization used here is one the catalog's entries also rely on.

1. **Unbounded memory.** A Turing machine needs an infinite tape; Conway's Life
   an infinite grid; Rule 110 an unbounded row. The native construction needs the
   infinite-context hypothesis (the context as unbounded tape); the finite
   construction needs an unbounded external store. *Identical idealization,
   relocated.* On finite hardware every catalog entry (and every real computer)
   is really a linear bounded automaton; the unbounded-memory assumption is what
   lifts all of them, uniformly, to TM power.

2. **An external clock / driver** — *finite regime only*. The TM construction's
   step must be re-invoked until the machine halts. The catalog explicitly
   accepts driven systems: CSS and PowerPoint are Turing-complete only with a
   user clicking to advance each step. Gwern calls such drivers "not as
   satisfying" but counts them, on the grounds that the driver "provides no
   logical or computational power." Ours is exactly that: a dumb re-invocation
   loop that decides nothing. The native construction needs no driver at all —
   consultation recursion supplies the control flow.

3. **A faithful interpreter.** The semantics must be executed as written. For
   CSS that executor is the browser; for Magic: The Gathering the 2019
   construction "forced all actions, rendering the construction fully
   mechanical"; for us it is any reader that follows the rules. The crucial point
   (§4) is that every step in both constructions is a *finite table lookup plus a
   local edit*, so a faithful interpreter can be a trivial deterministic parser —
   the computability claim does **not** depend on the interpreter being an LLM,
   or being intelligent at all.

## 2. The native construction: a universal evaluator as a child of the combinator

**The model.** SK combinatory logic — terms built from the atoms `S` and `K` by
application, rewritten by `S x y z → x z (y z)` and `K x y → x` — is a textbook
universal model: every λ-term, hence every computable function, compiles to an
SK term (bracket abstraction), and normal-order reduction computes it. It is the
same family of citation the catalog uses when an entry encodes λ-calculus, tag
systems, or Rule 110.

**The skill.** [`ski-eval`](.claude/skills/ski-eval/SKILL.md) is a child minted
by the combinator in the house style — frontmatter + topic section new, the
three kept sections verbatim (it *passes the structural gate*, unlike the
`word-rev-sub` sibling). Its topic is one recurrence:

> A term in normal form is answered directly. Otherwise, perform exactly **one
> leftmost-outermost rewrite** and consult the supporting file once on the
> resulting term; answer what the consultation returns.

One rewrite per consultation; the chain length is the number of reduction steps.
`Y(f) → f(Y(f))` grows the term, so there is **no well-founded measure** — the
chain may run forever. That is not a defect; it is the `collatz` case again, the
very shape the infinite-context combinator exists for, and it is *required*: a
total evaluator could not be universal.

**Forced steps.** Normal-order (leftmost-outermost) reduction has a *unique*
redex at every step, and each rule application is a local, mechanical rewrite —
the same "forced all actions" property as the Magic construction. The
δ-strictness clause (below) redirects to a unique argument, preserving
determinism. Nothing is left to judgement.

**The theorem.** Pure SK terms are a subset of the language `ski-eval`
normalizes. Any computable function is computed by normalizing some SK term;
`ski-eval` normalizes it by self-consultation alone. Hence, under the
infinite-context hypothesis plus a faithful interpreter, the skill formalism is
Turing complete — with the recursion mechanism the repo is *about* doing all the
work, and nothing bolted on. ∎

**Native numbers, honestly licensed.** The shipped `ski-eval` extends pure SK
with integer numerals and strict primitives (`add`, `sub`, `mul`, `eq`, `cond`),
plus `I`, `B`, `C`, and `Y` as primitive rules. This is the standard
*conservative* extension — δ-rules — with two precedents: **Plotkin's PCF**
(λ + naturals + cond + fixpoint) and **Turner's SK reduction machines**
(SASL/Miranda, 1979), which ran real programs on exactly S, K + literals +
strict arithmetic, never Church numerals. The universality theorem rests on the
pure fragment; the sugar exists because Church-numeral arithmetic makes terms
explode, and term size is where a stochastic interpreter drifts. The trade is
explicit: smaller terms, larger rule table. One strategy clause keeps δ-rules
deterministic: a strict primitive whose needed argument is not yet a literal
redirects the one rewrite into that argument — precisely what Turner's machine
did. And `Y(f) → f(Y(f))` as a primitive rule is the project's own object
appearing as one line of the machine it powers.

**It runs, and the repo grades it.** `harness/oracle.ml` contains a
deterministic normal-order SK+δ normalizer; `harness/results.txt` baselines
`ski-eval` from `I(42)` up to the flagship: `s-rec` compiled to combinators by
mechanical bracket abstraction,

    Y(B(S(C(B(cond)(C(eq)(0)))(5)))(C(B(C)(B(B(sub))(B(B(mul(2)))(C(B)(C(sub)(1))))))(3)))

whose application to `6` normalizes to `131` — matching the `s-rec 6 131`
baseline. The same oracle grades the recurrence computed *directly* by the
`s-rec` skill and computed *as a program* by the universal evaluator: the
repo's own examples run on its own universal machine.

## 3. The finite-context construction: simulate an arbitrary Turing machine

The native proof leans on the infinite-context hypothesis. This construction
refuses it and shows what recovers Turing power in a *finite* context: the disk
trampoline's external tape (the LBA→TM promotion of the README's gap section).

Fix any single-tape deterministic Turing machine

> M = (Q, Γ, δ, q₀, q_H, ␣),  with δ : (Q∖{q_H}) × Γ → Γ × {L,R} × Q.

We build a skill **S(M)** that simulates it.

**Data — the tape — lives on the external store.** The store holds one
*configuration*: the tape contents (a finite string over Γ, understood to be
padded with the blank ␣ in both directions), the head position, and the current
state q ∈ Q. This is precisely the trampoline state file the README specifies;
it has no size cap, so the tape is unbounded.

**Control — the transition table — lives in the skill body.** `S(M)`'s body is
δ, written out as instructions, one line per `(q, s)` pair:

> *If the state is `q` and the scanned symbol is `s`, write `s′`, move the head
> `D`, and set the state to `q′`.* — for `δ(q, s) = (s′, D, q′)`.
>
> *If the state is `q_H`, stop; the tape now holds the output.*

Because Q and Γ are finite, this is a **finite** list — bounded control.

**The step — one skill invocation.**

1. Read the configuration `(tape, head, q)` from the store.
2. Let `s` be the symbol at `head` (␣ if past the written region).
3. Select the **unique** body line matching `(q, s)`.
4. Apply it: overwrite the cell with `s′`, shift `head` by `D`, set `q ← q′`; if
   the head stepped past either end of the written region, extend it with one ␣
   (the store is unbounded, so this never fails).
5. Write `(tape, head, q)` back to the store.
6. If `q = q_H`, halt. Otherwise re-invoke (hand control to the driver, §1.2).

`(q, s) ↦ line` is a **total function on a finite domain**, so step 3 is a
forced, mechanical lookup — no choice, no judgement, nothing for intelligence to
contribute. Finite control over an unbounded tape, advanced by a deterministic
transition: **this is a Turing machine, by definition.** Since M was arbitrary,
`S(−)` simulates every Turing machine, so the skill formalism is Turing complete
under finite context + external store. ∎

### A concrete instance (so the construction isn't abstract)

The unary successor `n ↦ n+1`, tape alphabet `{1, ␣}`, one non-halting state
`A`, written as the body of `S`:

> - If the state is `A` and the scanned symbol is `1`: write `1`, move `R`, stay
>   in `A`. *(walk right over the block of 1s)*
> - If the state is `A` and the scanned symbol is `␣`: write `1`, move `R`, go to
>   `H`. *(append one 1 and halt)*
> - If the state is `H`: stop.

Hand it `111` with the head on the left: the driver runs the step four times
(`1,1,1,␣`) and halts with `1111` on the tape. The construction is δ-agnostic, so
a machine whose tape grows without bound (e.g. unary doubling, `n ↦ 2n`) is
handled by the *same* step with a different finite table — which is exactly how
the simulation exceeds any linear bounded automaton.

This instance is runnable: [`demo/unary-tm/`](demo/unary-tm/) ships the table as
`RULES.md` and a one-command driver (`sh demo/unary-tm/run.sh 3`), and documents
the LLM-as-CPU run (a fresh subagent per step over an external tape file) that
reproduced the same trace — the catalog-style implementation exhibit alongside
this construction.

## 4. Why the "stochastic interpreter" objection doesn't lower the grade

The one ground on which no other catalog entry sits is that our *default*
interpreter is a neural net, not a deterministic rule-engine. This does **not**
weaken the computability claim, for the same reason it doesn't weaken CSS's:

**Turing completeness is a property of the abstract step function the notation
defines, not of any particular executor.** In both constructions the step is a
finite lookup plus a local edit, mechanizable by a non-AI parser. Both have been
mechanized *in this repo*: the SK normalizer in `harness/oracle.ml` and the
shell driver in `demo/unary-tm/run.sh` execute the same notations an LLM reads,
and agree with the LLM-driven runs. The LLM is merely one interpreter of the
notation, and an imperfect one, exactly as physical silicon is a finite,
fault-prone interpreter of a program. Reliability of a given interpreter is an
**engineering** property, orthogonal to computability.

Every catalog entry makes this same split: CSS's Turing completeness is a fact
about the CSS specification, not about whether your browser has rendering bugs.
So on the *applicable* ground — "does the formalism express universal computation
under faithful semantics?" — y-skill stands with the catalog. The residual
difference (the default interpreter can err) is a reliability remark, and the
README's "Practical ceilings you hit first" already owns it.

## 5. Corroborating routes

Two independent constructions already make the claim robust; a third is
available for free: a **two-counter (Minsky) machine** — two naturals in the
store, a finite list of `inc` / `dec` / `jump-if-zero` instructions in the body —
is known-universal with even smaller control than a full TM, and would slot into
the finite regime unchanged.

## 6. Where y-skill sits against the catalog (honest placement)

| Ground | Catalog standard | y-skill |
|--------|------------------|---------|
| Reduction from a universal model | Rule 110 / cyclic tag / counter machine / λ-calculus | **✓** SK normalization, native (§2); TM simulation, finite regime (§3) |
| Fully mechanical / forced steps | MtG: "forced all actions… fully mechanical" | **✓** unique normal-order redex (§2); total δ lookup on a finite domain (§3) |
| Unbounded-memory idealization | infinite tape / grid / row | **✓** shared — infinite context (§2) or external store (§3) |
| External clock / driver | CSS, PowerPoint (user clicks; "not as satisfying") | **✓** finite regime only; the native construction needs none |
| Faithful interpreter | browser (CSS), game rules (MtG) | **✓** both steps parser-executable, and mechanized in-repo (oracle, shell driver) |
| Accidental / surprising | the catalog's inclusion criterion | **✗ N/A** — y-skill is *intentional* |

The last row is the only one y-skill "fails," and it is a **scope** criterion,
not a **rigor** criterion. Gwern's catalog deliberately *excludes* intentionally
computational systems (FRACTRAN, Malbolge, and Game of Life are named
exclusions). y-skill was *built* to express recursion, so it belongs next to "is
Lisp Turing complete?" rather than on the list of accidents. On every *applicable*
(rigor) ground, it matches.

## 7. The caveat, kept honest

The theorems are about the **idealized systems**: skill + infinite context (§2),
or skill + unbounded store (§3), each + faithful interpreter. A physical run is
a bounded-memory, probabilistic *approximation* — true of every catalog entry on
finite hardware, with the one extra wrinkle that our default interpreter can
make mistakes. What the constructions settle is the question of *kind*: the
skill formalism is not a weaker automaton that merely looks expressive; given
the same idealizations everyone else is granted, it is Turing complete — and in
the native regime, it is Turing complete *through the very self-consultation
mechanism the repo exists to exhibit*. See the README section "The
infinite-context idealization and the gap" for the finite-reality side of the
ledger.
