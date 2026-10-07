# Is y-skill Turing complete? A construction

This note upgrades the hand-wave ("look, a Y combinator and a non-terminating
recurrence") into the kind of argument the
[*Surprisingly Turing-Complete*](https://gwern.net/turing-complete) catalog
accepts: a **general reduction** from a known-universal model, made **fully
mechanical**, with every idealization **stated** and **matched** to the ones that
catalog already grants its entries.

## The claim

> Under its intended (faithful) semantics, and given an external unbounded store,
> the Claude-Skill formalism can simulate an arbitrary Turing machine. Hence it
> is Turing complete.

Two qualifiers appear in that sentence — *faithful semantics* and *unbounded
store*. Neither is a dodge; both are idealizations the catalog makes for every
entry (§1). On the grounds that actually distinguish a proof from a claim —
generality and mechanical forcing — this construction matches the catalog (§2,
§5).

## 1. The idealizations, and that they match the catalog

Turing completeness is *always* a statement about an idealized model, never about
a physical device (your laptop has finite RAM and is, strictly, a finite-state
machine). Three idealizations are in play here; each is one the catalog's
entries also rely on.

1. **Unbounded memory.** A Turing machine needs an infinite tape; Conway's Life
   an infinite grid; Rule 110 an unbounded row. We need an unbounded external
   store — the "disk trampoline" tape already described in the README. *Identical
   idealization.* On finite hardware every entry (and every real computer) is
   really a linear bounded automaton; the unbounded-memory assumption is what
   lifts all of them, uniformly, to TM power.

2. **An external clock / driver.** Our step must be re-invoked until the machine
   halts (a background driver, or the `/loop` skill). The catalog explicitly
   accepts driven systems: CSS and PowerPoint are Turing-complete only with a
   user clicking to advance each step. Gwern calls such drivers "not as
   satisfying" but counts them, on the grounds that the driver "provides no
   logical or computational power." Our driver is exactly that: a dumb
   re-invocation loop that decides nothing.

3. **A faithful interpreter.** The semantics must be executed as written. For
   CSS that executor is the browser; for Magic: The Gathering the 2019
   construction "forced all actions, rendering the construction fully mechanical";
   for us it is any reader that follows the rules. The crucial point (§3) is that
   our per-step rule is a *finite table lookup plus a local edit*, so a faithful
   interpreter can be a trivial deterministic parser — the computability claim
   does **not** depend on the interpreter being an LLM, or being intelligent at
   all.

## 2. The construction: simulate an arbitrary Turing machine

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
under the idealizations of §1. ∎

This is the README's "bounded finite control + unbounded tape" upgrade from LBA
to TM — now *carried out as a general construction* rather than asserted.

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

## 3. Why the "stochastic interpreter" objection doesn't lower the grade

The one ground on which no other catalog entry sits is that our *default*
interpreter is a neural net, not a deterministic rule-engine. This does **not**
weaken the computability claim, for the same reason it doesn't weaken CSS's:

**Turing completeness is a property of the abstract step function the notation
defines, not of any particular executor.** `S(M)`'s step is a finite lookup plus
a local tape edit. That function is *mechanizable by a non-AI parser* — you could
execute `S(M)` with a hundred lines of shell. The LLM is merely one interpreter
of the notation, and an imperfect one, exactly as physical silicon is a finite,
fault-prone interpreter of a program. Reliability of a given interpreter is an
**engineering** property, orthogonal to computability.

Every catalog entry makes this same split: CSS's Turing completeness is a fact
about the CSS specification, not about whether your browser has rendering bugs.
So on the *applicable* ground — "does the formalism express universal computation
under faithful semantics?" — y-skill now stands with the catalog. The residual
difference (the default interpreter can err) is a reliability remark, and the
README's "Practical ceilings you hit first" already owns it.

## 4. Corroborating routes (robustness)

A single reduction suffices, but three independent ones make the claim robust;
each mirrors a technique the catalog uses.

- **λ-calculus.** The repo already carries the Y combinator. Extending the
  self-consultation to encode application and abstraction gives the standard
  λ-calculus route — the same family as the catalog's PostScript / font
  stack-machine encodings.
- **Two-counter (Minsky) machine.** Hold two naturals in the store and a finite
  list of `inc` / `dec` / `jump-if-zero` instructions in the body. Known
  universal, with even smaller control than a full TM.
- **Turing machine.** §2, above — the most self-evidently convincing, and the one
  that reuses the repo's own tape architecture.

## 5. Where y-skill sits against the catalog (honest placement)

| Ground | Catalog standard | y-skill |
|--------|------------------|---------|
| Reduction from a universal model | Rule 110 / cyclic tag / counter machine / λ-calculus | **✓** TM simulation (§2); also λ and 2-counter (§4) |
| Fully mechanical / forced steps | MtG: "forced all actions… fully mechanical" | **✓** total δ lookup on a finite domain |
| Unbounded-memory idealization | infinite tape / grid / row | **✓** shared — the store *is* the tape |
| External clock / driver | CSS, PowerPoint (user clicks; "not as satisfying") | **✓** shared — dumb re-invocation loop, no compute |
| Faithful interpreter | browser (CSS), game rules (MtG) | **✓** step is parser-executable; the LLM is just one interpreter (§3) |
| Accidental / surprising | the catalog's inclusion criterion | **✗ N/A** — y-skill is *intentional* |

The last row is the only one y-skill "fails," and it is a **scope** criterion,
not a **rigor** criterion. Gwern's catalog deliberately *excludes* intentionally
computational systems (FRACTRAN, Malbolge, and Game of Life are named
exclusions). y-skill was *built* to express recursion, so it belongs next to "is
Lisp Turing complete?" rather than on the list of accidents. On every *applicable*
(rigor) ground, it matches.

## 6. The caveat, kept honest

The theorem is about the **idealized system**: skill + unbounded store + faithful
interpreter. A physical run is a bounded-memory, probabilistic *approximation* of
it — true of every catalog entry on finite hardware, with the one extra wrinkle
that our default interpreter can make mistakes. What the construction settles is
the question of *kind*: the skill formalism is not a weaker automaton that merely
looks expressive; given the same idealizations everyone else is granted, it is
Turing complete. See the README section "The infinite-context idealization and
the gap" for the finite-reality side of the ledger.
