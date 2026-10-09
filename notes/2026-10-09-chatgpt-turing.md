# ChatGPT on y-skill and LLM Turing completeness

*Conversation with ChatGPT about [github.com/cuihtlauac/y-skill](https://github.com/cuihtlauac/y-skill),
title "Assessing LLM Turing Completeness". Local copy of the share link
https://chatgpt.com/share/6ac84ead-6e20-83eb-ada8-5b1726018389, fetched 9 October 2026.
ChatGPT's UI widgets were flattened to Markdown, its inline source citations
(opaque `turn…` ids) dropped, and the trailing follow-up suggestions removed.
A redacted plugin (web search) message was omitted.*

### User

How does my https://github.com/cuihtlauac/y-skill fit in the state of art of knowledge on LLM and agents turing completeness?

---

### ChatGPT

# `y-skill` and the Turing completeness of LLM agents

My assessment is that your [`cuihtlauac/y-skill`](https://github.com/cuihtlauac/y-skill) is an interesting *constructive demonstration of computational universality through an agent interface*, rather than merely another example of an LLM solving programming problems.

The important distinction is that you are not trying to prove that a neural network, by itself, is a Turing machine. You are exploring whether a language-model agent, given a self-referential instruction artifact and an execution protocol, can implement recursion and universal computation without adding a conventional interpreter to the agent runtime.

Your repository makes this concrete: a Claude Skill consults its own `SKILL.md` on smaller cases, uses the Y combinator as its conceptual model, and includes an SK-combinator evaluator and a Turing-machine demonstration. It also explicitly acknowledges the gap between an idealized infinite context and actual finite-context execution.

That places the project at the intersection of three research areas:

- **Computational universality:** what operations are sufficient to express arbitrary computation?
- **LLM agents and external memory:** how much computational power comes from the surrounding system rather than the model?
- **Executable specifications and agent protocols:** can an ordinary instruction file serve as a recursive program, without a purpose-built interpreter?

The strongest contribution is the way you make those ideas tangible in a real agent interface.

## 1. Where it sits relative to existing research

The closest prior work is surprisingly direct: a 2023 paper titled *Memory Augmented Large Language Models are Computationally Universal*. It shows how a transformer-based language model combined with associative read-write memory can simulate a universal Turing machine, without modifying the model's weights.

That means the broad proposition — *an LLM-based system can be computationally universal* — is not new. Your project is more interesting at the level of the mechanism.

**Memory-augmented LLMs (2023)**

External memory as computational substrate

The memory provides persistent read/write state; the system's execution mechanism implements the computation. The paper establishes a formal universality result for a particular construction.

**Your `y-skill`**

Self-reference as the recursion mechanism

The skill's own instructions are the recursive definition. In the idealized version, the consultation chain itself carries the computation; in the finite-context version, an external tape and re-invocation driver carry the state and control flow.

The difference is not simply that your implementation uses Markdown instead of a database. It is that you isolate a specific programming-language idea — the fixed-point operator — and express it through an existing agent protocol.

This gives `y-skill` a useful position among related work:

| Research area | What it establishes | What `y-skill` adds |
|---|---|---|
| Universal computation with external memory | An LLM-plus-memory system can simulate a universal machine | A concrete self-referential instruction mechanism |
| Recursive prompting and decomposition | A task can be broken into smaller model calls | Recursion is made part of the skill's own semantics |
| Tool-using agents | Models can orchestrate external computation | A deliberately minimal computational formalism |
| Turing-complete systems such as lambda calculus and SK combinatory logic | A small set of rules can express universal computation | An attempt to instantiate those rules through an agent skill |

The broader agent literature increasingly treats reasoning, memory, and tool execution as separate architectural components. Your project makes their computational roles unusually explicit.

## 2. The key theoretical distinction: three different claims

The phrase *Turing-complete LLM* can refer to three quite different propositions. Your repository is strongest when these are kept separate.

**A. The skill formalism is universal** — *Strongest claim*

Your `ski-eval` construction uses SK combinatory logic, a known universal computational formalism. Under the specified rewriting rules, a faithful interpreter can evaluate universal programs. The proof reduces the claim to this established formalism.

**Status:** a sound mathematical route, provided the operational semantics and reduction are fully specified.

**B. The agent can execute the formalism faithfully** — *Empirical claim*

A language model must select the right rewrite, preserve the state, follow the recursion protocol, and return the correct result at each step.

Your OCaml oracle, behavioural grading, and deliberately corrupted-rule experiment are valuable because they test this separately from the formal proof.

**Status:** demonstrated for tested executions, not guaranteed for arbitrary inputs or unbounded execution.

**C. The deployed agent is Turing-complete in practice** — *Requires qualification*

Actual execution has finite context, finite storage, finite budgets, and a probabilistic interpreter. The native construction assumes unbounded context; the alternative construction assumes unbounded external storage and a driver that keeps invoking the skill.

**Status:** an idealized universality result, not a claim that any particular deployed Claude session can run arbitrarily long or correctly.

The subtle point is that the external-tape construction is not, by itself, evidence that an LLM has gained computational power unavailable to conventional software. A deterministic program could execute the same transition table. Its value is that it demonstrates how an agent skill can *specify and participate in* a universal machine with a very thin execution harness.

The native construction is conceptually more distinctive: it makes the recursive consultation mechanism itself the computational control flow.

## 3. The most interesting question: is the Y combinator really doing the work?

I think this is where your project has the most conceptual value.

In conventional programming, recursion is usually implemented by a language construct, a function call, a stack, or an interpreter. The lambda calculus gives a more fundamental explanation: recursion can be expressed through a fixed point.

```
Y f = f (Y f)
```

Your skill translates that idea into a protocol: to solve a non-base case, consult the same skill on a smaller case. The recursive definition is not a separate executable program. It is embedded in the instructions that govern how the skill is used.

There is an important distinction here:

- **Self-reference** is not sufficient for universality. A document can refer to itself without performing any computation.
- **Recursion** permits an unbounded sequence of computational steps in an idealized execution model.
- **Universality** requires the ability to represent and execute a known universal formalism, not merely to express recursive-looking tasks.

Your `ski-eval` construction addresses that last requirement. It is a stronger argument than demonstrating factorial, Fibonacci, or another familiar recurrence because SK combinatory logic supplies an established route to universality.

The real research question is therefore not whether the letter `Y` appears in a skill. It is whether the agent's operational semantics faithfully implement the fixed-point construction.

### One caveat about the infinite-context argument

Infinite context is a legitimate theoretical idealization, but it deserves careful treatment. A real LLM does not have an infinite context window, and recursive consultation does not automatically guarantee that earlier computational state remains available or that each step is correct.

Your second construction, using an external tape and a re-invocation driver, handles this differently: it moves unbounded state out of the context and makes each invocation one transition of the machine. This is a valid route to a Turing-complete *system under the stated assumptions*, but it should not be conflated with proving that a bounded-context model alone is universal.

## 4. What I would compare it against in the literature

These are the most relevant starting points for positioning the project in a paper or technical note.

**1. Schuurmans (2023) — Memory-augmented computational universality**

Closest theoretical predecessor

Shows how an LLM with external associative memory can simulate a universal Turing machine. This is the key citation to acknowledge when claiming universality for an LLM-based system.

[Read the paper](https://arxiv.org/abs/2301.04589)

**2. Gwern — Surprisingly Turing-Complete**

Standard for constructive demonstrations

A useful reference for how to present a reduction from a known universal system, explain idealizations, and distinguish formal universality from practical execution. Your `PROOF.md` explicitly uses this style of argument.

[Read the catalogue](https://gwern.net/turing-complete)

**3. Xu et al. (2025) — LLM-Based Agents for Tool Learning: A Survey**

Agent architecture and execution context

Surveys tool selection, task decomposition, planning, execution, and evaluation. It helps situate your work in agent research, although it is not itself a proof of computational universality.

[Read the survey](https://doi.org/10.1007/s41019-025-00296-9)

**4. Wölflein et al. (2025) — LLM Agents Making Agent Tools**

Related agent engineering

Explores agents that construct and debug tools from research papers and code. This is relevant to the broader idea of agents producing executable capabilities, but the paper addresses tool construction rather than fixed-point recursion.

[Read the paper](https://aclanthology.org/2025.acl-long.1266/)

## 5. What would make `y-skill` a stronger research contribution?

Your repository already has several elements that improve its credibility: a formal proof document, an OCaml reference implementation, a structural invariant, a behavioural harness, and a negative test for a deliberately corrupted rule.

I would focus on four extensions.

1. **Separate the theorem from the implementation.** Define the abstract skill semantics and prove its universality independently of Claude. Then specify exactly which properties an LLM executor must satisfy to implement those semantics. This avoids relying on an informal notion of a model being a faithful interpreter.
1. **Measure interpreter fidelity.** Test each transition against the oracle across multiple models, prompts, and execution depths. Report per-step accuracy, complete-run accuracy, and failure modes. A system that is correct for 99.9% of individual steps may still be unreliable over long executions.
1. **Compare execution architectures.** Measure native self-consultation against the external-tape trampoline, and against direct deterministic execution. Record token usage, latency, maximum completed computation, and error rates. This would quantify what the skill abstraction buys you, beyond formal expressiveness.
1. **Test the generality of the programming model.** Demonstrate that independently specified algorithms can be generated as skills and executed without changing the recursion mechanism. Your meta-skill's ability to mint new recursive skills is particularly relevant here.

The most scientifically useful outcome would be a clear separation between three measurements: *expressive power*, *execution fidelity*, and *computational cost*. Turing completeness establishes only the first.

## 6. My overall assessment

I would position `y-skill` as a small, deliberately constructed example of **computational universality expressed through an LLM agent's instruction protocol**.

It is not the first demonstration that LLMs with memory can support universal computation. Its distinctive angle is the attempt to realize recursion as a self-referential skill, then connect that construction to a known universal formalism and to a practical finite-context simulation.

The strongest claim to make is:

> `y-skill` demonstrates a route to Turing-complete computation through self-referential agent instructions, under explicit assumptions about memory and faithful execution. Its contribution is the computational construction and its realization in an agent skill, rather than the general discovery that LLM-based systems can be universal.

That is both defensible and more interesting than a generic claim that LLMs are Turing-complete.

One final distinction matters for how you present it: if your target is the programming-languages community, lead with the fixed-point construction and operational semantics. If your target is the LLM-agent community, lead with the boundary between model capability and system capability, and use the two execution regimes to make that boundary precise.
