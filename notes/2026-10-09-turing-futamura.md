# y-skill: Turing completeness, interpreters and Futamura

*Conversation with Claude, 9 October 2026, about [github.com/cuihtlauac/y-skill](https://github.com/cuihtlauac/y-skill).*

*Local copy of the Google Doc
[y-skill — Turing completeness, interpreters and Futamura (chat with Claude, 9 Oct 2026)](https://docs.google.com/document/d/1Sv7vxYKFhQyW3AbiROK5mujPgjjnzSNwuHwwL_tmWPk/edit),
fetched 9 October 2026.*

## 1. How does y-skill fit in the state of the art on LLM and agent Turing completeness?

The project is careful and well-documented, but its Turing-completeness argument sits in a well-developed research area that TLDR.md and PROOF.md don't cite. The skill-loading mechanism is novel. The computability result itself has close precedents, and those precedents set a stricter standard of proof that y-skill could adopt.

### The literature the related-work section is missing

The related-work table compares y-skill to other recursive skills and agents, and uses Gwern's catalog as the standard for rigor. The closer comparison is a line of work by Dale Schuurmans and collaborators, who ask whether a real, prompted LLM is a universal computer and answer it about specific deployed models.

- **Schuurmans (2023), "Memory Augmented Large Language Models are Computationally Universal"** is essentially the finite regime, published three years earlier. It argues that a deterministic language model conditioning on bounded-length strings is equivalent to a finite automaton, and shows that Flan-U-PaLM 540B with an associative read-write memory can exactly simulate the universal Turing machine U15,2, without modifying weights, via a stored-instruction computer programmed by prompts. The disk trampoline and demo/unary-tm are this construction.
- **Schuurmans, Dai and Zanini (2024), "Autoregressive Large Language Models are Computationally Universal"** corresponds to the native regime. Autoregressive decoding alone, with emitted tokens appended as the context window advances, corresponds to a Lag system. They compile a universal TM into 2027 production rules and show a single system prompt drives gemini-1.5-pro-001, under greedy decoding, to apply each rule correctly.
- **Lewandowski, Machado and Schuurmans (2026), "Universal computation is intrinsic to language model decoding"** argues that even randomly initialized models are universal under autoregressive decoding, so training improves programmability rather than expressiveness. They redid the verification on open-weight Llama-4 because the Gemini model had been deprecated; the same reproducibility concern applies to Claude model versions.
- **Qiu et al. (ICLR 2025), "Ask, and it shall be given: On the Turing completeness of prompting"** proves there exists a finite-size Transformer such that for any computable function some prompt makes it compute that function. A SKILL.md is a prompt, so this is the theoretical backdrop.
- **Classical architecture expressivity:** Siegelmann and Sontag on RNNs; Pérez et al., "Attention is Turing-complete" (infinite precision); Merrill and Sabharwal, showing a single forward pass is bounded by TC0 while chain-of-thought steps add power. The consultation chain is a structured chain of thought.

### Where the comparison bites

**The faithful-interpreter argument in §4 gives away the interesting claim.** If Turing completeness is a property of the notation, the theorem says only that a Markdown description of SK reduction is Turing complete, which is true of any written spec and says nothing about Claude. Schuurmans makes a proof-of-simulation about the actual model: because the rule set is finite, correctness reduces to checking the model's output on each of a finite set of prompts. The oracle tests sample traces; they don't enumerate the rule table.

**SK is a poor vehicle for that kind of proof.** S x y z → x z (y z) duplicates a subterm of unbounded size, and finding the leftmost-outermost redex means scanning an arbitrarily large term. The set of per-step inputs is infinite and can't be exhaustively verified. That is why the precedents use TMs, tag systems or Lag systems with bounded local windows.

**The infinite-context hypothesis is not quite the infinite tape.** A TM head reads one cell; the native regime conditions each step on the entire growing transcript, with finite precision and positional resolution.

**Decoding must be deterministic.** The precedents use greedy decoding, temperature zero and fixed seeds. Claude Code doesn't expose that, so the interpreter is formally stochastic; with per-step error ε, success decays like (1−ε)^T.

### What is genuinely y-skill's own

Recursion carried by the skill-loading mechanism itself, a meta-skill acting as fixpoint operator by copying its carried sections verbatim, and the "base cases plus how other cases are built" programming model. The anti-recitation methodology (non-textbook recurrences, the faithfully-wrong broken-coefficient test) belongs with counterfactual-task evaluations of LLM reasoning. Conceptually, recursing by pointing at "this same SKILL.md" uses a name supplied by the environment, so it is closer to let rec, Kleene's recursion theorem or quines than to Y proper.

### A path to a stronger result

In the finite regime, where each step sees bounded input, compile a small universal machine (U15,2, a 2-tag system or a Minsky machine) into RULES.md, call a pinned Claude model via the API at temperature 0, and verify every (state, symbol) rule exhaustively. That gives "Claude plus this skill plus an external tape is provably a universal computer", matching the Schuurmans standard applied to skills.

## 2. Does the lambda calculus respect the finite regime?

Not as written, but it can be made to.

### Why plain λ-calculus and SK break it

- **Copying is unbounded.** β-reduction copies N into every occurrence of x; S duplicates z.
- **Finding the redex is not local.** Leftmost-outermost search walks an arbitrarily long spine.
- **Terms can blow up.** Size explosion: terms can grow exponentially in the number of β-steps. Accattoli and Dal Lago's result that leftmost-outermost β-steps are a reasonable cost model relies on sharing.

So the current ski-eval lives only in the native regime, and its rules can't be exhaustively verified.

### How to make it respect the finite regime

**Graph reduction** (Turner's SK machine): a heap of application nodes and a spine stack on the store; each rule is a constant-size pointer edit, and S shares x rather than copying it. The rule table becomes finite. Bonus: Y becomes a cyclic node, a single self-referential cell, instead of a term that grows at each unfolding.

**Abstract machines** (Krivine, CEK, SECD) split evaluation into small transitions over a term pointer, environment and continuation stack.

**Interaction nets / interaction combinators** (Lafont): a finite set of local, constant-size rules, universal with three agent types; the best match for an exhaustively verifiable proof.

### Remaining caveats

**Pointers are unbounded names.** Addresses grow like log(heap size); the rule table is finite only if addresses are opaque tokens copied verbatim (as in Schuurmans's associative memory). The fully rigorous alternative is encoding the heap on a finite-alphabet tape.

**Native integers break boundedness.** Use digit-by-digit arithmetic in the store or bounded numerals, with universality resting on the pure fragment.

## 3. How critical is anonymous execution, e.g. /y-skill [anonymous function] [initial data]?

**For computability: not critical.** Named and anonymous recursion are equally expressive. ski-eval already gives anonymous execution: an anonymous program passed as data to a fixed evaluator.

**For the "this is Y" claim: moderately important.** Minted children recurse via a filename. An anonymous mode closes most of the gap, though y-skill's own file remains a named primitive, like a built-in fix. Strict anonymity would mean in-context self-application: the frame sees the text of f and applies it to itself and the smaller case, with no file read. That fits the native regime, at constant extra cost per frame.

**For verification: important and favourable.** Minted children each need their own proof-of-simulation. A fixed interpreter taking the program as data is a stored-program machine, verified once, which is the architecture the Schuurmans results verify. This only works if f is in a formal language; natural-language step descriptions can't be checked exhaustively.

**Open recursion pays off practically:** memoization (Y(memo ∘ f), collapsing g-rec to linear), fuel or depth limits (graceful failure for /collatz 27), and tracing wrappers.

**Cost:** minting is compilation (partial evaluation, Kleene's s-m-n); anonymous execution is interpretation, with more tokens per frame.

**Suggested setup:** keep /y-skill name topic as the compiler; add an interpreter mode (prose for demos, a formal-language version such as graph-reduction ski-eval for the proof).

## 4. Isn't building an interpreter after a compiler going backward on Futamura's projections?

No. The projections go from interpreter to compiler; y-skill built the compiler first by hand. Adding the interpreter supplies the reference semantics the compiler should be derived from.

- **First projection, mix(int, f):** a compiled program for f. This is a minted child, with the model following y-skill's instructions as the specializer.
- **Second projection, mix(mix, int):** a compiler. This is where y-skill sits, written by hand.
- **Third projection, mix(mix, mix):** a compiler generator. Self-application is syntactically trivial when every artifact is a prompt, but correctness is not guaranteed.

y-skill is a trivial (s-m-n) specializer: it concatenates the fixed program onto unchanged generic code. It is not Jones-optimal, but it is sound almost by construction, and the byte-identical-tail gate certifies the child is exactly "interpreter with f fixed".

**What the interpreter buys:** a testable correctness equation child_f(x) = int(f, x) for the harness; universality proved once on the interpreter, with children inheriting correctness through the specializer's soundness (a reason to keep the specializer trivial). The equations are theorems only when f and the interpreter are formal; with prose they are hypotheses to test.

## 5. Should there be a /build-y-skill-run [syntax] that generates the specialized interpreter for a formal language?

Mostly yes, with three adjustments.

**It needs semantics, not syntax.** The argument should be a rule set, restricted to finite local rewrite systems (TM tables, tag and Lag systems, interaction nets, bounded graph rewriting) so each step is a finite table lookup.

**Its place in Futamura's scheme.** With a generic rewrite-system interpreter int_rw(R, term), mix(int_rw, R) = int_L is the first projection one level up, and /build-y-skill-run plays the role of mix(mix, int_rw). Keep the specialization trivial: concatenate the rule table onto fixed, verbatim machinery checked byte for byte.

**It doesn't remove the need for a verified core.** Every generated interpreter is a new prompt. Use translation validation: the generator emits the interpreter skill, a deterministic reference interpreter from the same R, and an exhaustive per-rule test suite run at temperature 0 on a pinned model.

**Overall architecture:** a single verified core for a small universal machine (graph-reduction SK, interaction combinators or U15,2); /build-y-skill-run as a validated front-end factory, cross-checked via int_L(p, x) = core(compile(p), x); /y-skill as the trivial specializer, with child_f(x) = int(f, x) in the harness. Prior art for deriving interpreters from semantics: the K framework and PLT Redex.

## References

- [Schuurmans (2023), Memory Augmented Large Language Models are Computationally Universal](https://arxiv.org/abs/2301.04589)
- [Schuurmans, Dai, Zanini (2024), Autoregressive Large Language Models are Computationally Universal](https://arxiv.org/abs/2410.03170)
- [Lewandowski, Machado, Schuurmans (2026), Universal computation is intrinsic to language model decoding](https://arxiv.org/abs/2601.08061)
- [Qiu et al. (ICLR 2025), Ask, and it shall be given: On the Turing completeness of prompting](https://arxiv.org/abs/2411.01992)
- [Gwern, Surprisingly Turing-Complete](https://gwern.net/turing-complete)
- Also cited from memory: Pérez, Barceló, Marinković, Attention is Turing-complete (JMLR 2021); Merrill and Sabharwal, The Expressive Power of Transformers with Chain of Thought (ICLR 2024); Accattoli and Dal Lago, Beta reduction is invariant, indeed; Lafont, Interaction combinators; Jones, Gomard and Sestoft, Partial Evaluation and Automatic Program Generation.
