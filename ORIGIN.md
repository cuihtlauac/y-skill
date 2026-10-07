# Origin: how a tired cat became a skill that writes skills

This project began, as these things do, with a cat. On 5 October 2026 I opened
a conversation with Gemini on the most worn-out sentence in machine learning:
*"the cat sat on the mat because it was tired."* It is the textbook example
for [self-attention](https://arxiv.org/abs/1706.03762) — mats don't get tired,
so the model binds "it" to "cat." Gemini dutifully produced the softmax
formulas. I wasn't after formulas. *Forget the math — what are we actually
talking about?* Answer: attention is an oriented, weighted bond between
tokens. Words like "it" are empty cups; the surrounding sentence pours meaning
into them.

That reframing invited a sharper question: *which* words need these bonds? We
sorted them into four classes — ambiguous homographs ("bank"), deictic pointer
words ("there," "now"), anaphoric stand-ins ("it," "does"), and relative
modifiers ("large," which means nothing until it latches onto "mouse" or
"galaxy").

Staring at that list, I saw something familiar. Those four classes look like a
probabilistic version of the
[lambda calculus](https://en.wikipedia.org/wiki/Lambda_calculus): homograph
clashes are terms without α-renaming, deictics are free variables awaiting an
environment, anaphora is a let-binding resolved by β-reduction, and modifiers
are function application. Attention, on this view, is a soft, differentiable
interpreter — a variable can be 80% bound to "the cat" and 20% to "the mat."
Gemini claimed published research backs the correspondence (neural lambda
calculus, Transformer type inference); those citations came from a chatbot and
I'd want to check them before leaning on them, but the structural mapping
stood on its own.

Then a detour I couldn't resist: is *anaphora* versus
[*anamorphism*](https://en.wikipedia.org/wiki/Anamorphism) a coincidence, or
is there something to dig? Not a coincidence — the same Greek directional
prefixes, *ana-* and *cata-*, feed both vocabularies — but the two fields
mapped them in opposite directions. Linguists named for how the eye scans the
page: anaphora points *backwards* to a word already said, cataphora *forwards*
to one still coming. The
[Bananas paper](https://research.utwente.nl/en/publications/functional-programming-with-bananas-lenses-envelopes-and-barbed-w)
authors named for how data grows: an anamorphism *unfolds* a seed into a
structure, a catamorphism *folds* a structure down to a value. The mechanics,
though, cross over the naming. Resolving an anaphoric "it" is catamorphic: a
fold over the preceding context, tearing it down until it reduces to the
antecedent (*it = cat*). Cataphora is anamorphic: "When *he* arrived, John
noticed…" opens a lazy slot before the data exists, an unfold holding a
promise that a downstream value will bind it. Recursion schemes were now in
the frame, and recursion schemes lead to one place.

## The sentence

So I asked: *how would a combinator like Y look in natural language?* Gemini's
first answers were loops — "a rumor is a story told by someone who heard a
rumor," liar paradoxes, the repetition traps that autoregressive models fall
into. Loops weren't what I wanted; I wanted structure. *Make a real
Y-combinator sentence, following its exact structure.* Mirror
λf.(λx.f(x x))(λx.f(x x)), with an explicit self-application driver, not just
a snake eating its tail. Out came:

> Tell a story by applying [the following rule] to [itself]: The rule is to
> speak of a traveler who is trapped inside [the story].

Execute it and the story unfolds forever: a traveler trapped inside a story
about a traveler trapped inside a story about a traveler. It read to me like
the pitch of a Borgesian short story, and Gemini agreed — this is the
[602nd night](https://en.wikipedia.org/wiki/One_Thousand_and_One_Nights) on
which (Borges claims) Scheherazade begins telling the King his own story, and
[*The Circular Ruins*](https://en.wikipedia.org/wiki/The_Circular_Ruins), a
dreamer who discovers he is being dreamed. A fixed point, told as fiction.

## The story becomes a skill

The sentence did not stay in Gemini. I carried it to a second session, this
time with Claude, and opened with it verbatim: *how does this sentence relate
to the Y combinator?* From that question the session went straight to
construction. The traveler-in-the-story rule — a rule applied to itself that
generates unbounded structure — was rebuilt as a
[Claude Skill](https://code.claude.com/docs/en/skills): a `SKILL.md` whose
only supporting file is *itself*, and whose payload is instructions for
minting further skills built the same way.

The rest of that session was engineering the fixed point into a usable tool.
The boilerplate invocation ("make a new skill on another topic, following your
section…") felt like code I shouldn't have to retype, so it moved out of the
prompt and into the skill — `/y-skill hanoi-moves <topic>` now suffices. The
dispatch rule went deliberately into the *replaceable* payload section, the f
of Y f, so that generated children don't inherit skill-making and
`/hanoi-moves 3` isn't misread as a request to build a skill named "3." I had
the skill renamed `y-skill`. And the session closed on the question that still
drives the harness in this repository: a generated `/fibonacci` skill
answering "8" for F(6) proves nothing, because the model already knows
Fibonacci. What proves recursion is the *call log* — 25 consultations, each
case consulting exactly n−1 and n−2, each run as a separate subagent given
only the SKILL.md and a smaller case.

By the close of that session the sentence had finished its migration: a
pronoun resolving to a cat, attention read as a probabilistic lambda calculus,
a one-sentence story about a trapped traveler — now
[`y-skill/SKILL.md`](.claude/skills/y-skill/SKILL.md), a skill trapped inside
the skill it tells. The traveler had moved in. What it still lacked was a home
that could outlive a chat window.

## From sentence to repository

The git log picks up where the transcripts leave off. The repository was born
on 6 October 2026, the day after the conversations, and the first real commit
is the punchline itself: *"Add y-skill: the Y combinator as a Claude Skill."*
The same day brought [PROMPTS.md](PROMPTS.md) and a README — and then the
design decision that shapes everything here, adopting the *infinite-context
hypothesis*: the combinator assumes chains of self-consultations may be
unbounded, so termination belongs to the topic, never to the combinator. Y
doesn't decide when to stop; f does.

The worry that closed the Claude session — a right answer proves nothing,
because the model already knows Fibonacci — became machinery that afternoon: a
shell-and-Make [harness](harness/) with an OCaml oracle as ground truth. Two
gates guard every generated skill. A structural gate
([structural.sh](harness/structural.sh)) checks that the kept tail of each
child is byte-identical to `y-skill/SKILL.md` — the fixed point, enforced with
`diff`. A behavioural gate ([grade.sh](harness/grade.sh)) checks answers
against baselines in [results.txt](harness/results.txt) that must come from
[oracle.ml](harness/oracle.ml), never from the model, with a negative control
(`make broken`) proving the gates can actually fail. The generated skills
themselves are gitignored, not committed: a fresh clone ships only the
combinator, and `g-rec`, `collatz`, `word-rev` and the rest are regenerated by
running `/y-skill`. The same day also logged a negative result:
`word-rev-sub`, a sibling combinator that consults by spawning subagents,
which doesn't scale because subagents in this harness nest only one level deep
— breadth, not depth.

7 October was for the theory. [PROOF.md](PROOF.md) added the
Turing-completeness constructions, [demo/unary-tm](demo/unary-tm/) a runnable
Turing machine as a skill, and `ski-eval` the native construction: a generated
skill that normalizes SK combinator terms one rewrite per self-consultation —
so the skill minted by the Y combinator now evaluates the literal Y
combinator, and the baselines end with Y-encoded recursive terms ground
through dozens of single rewrites (alongside `mul(6)(7)` computing 42). The
day closed with housekeeping: the long story split into [TLDR.md](TLDR.md) so
the README could stay short, then two review passes fixing doc drift and
hardening the harness.

## How this document was written

Fittingly for this project, the story above was not written by its narrator.
Claude Code wrote it, working from saved transcripts of the two sessions: the
Gemini conversation of 5 October 2026 and the Claude session that followed.
The brief was to read them in order, extract the single arc — attention,
lambda calculus, the natural-language Y combinator, the story turned skill —
and drop the side discussions: Kotlin's `it` keyword, multi-agent security
loops, and a detour through the Curry-Howard correspondence.

The first draft told the story in the third person: "the user observed," "the
conversation sorted them." Then came a change of subject, grammatically: on
request, the document was retold in the first person, in the voice of the
person who had the conversations. So the "I" above is real but reconstructed —
every insight and prompt attributed to it comes from the transcripts, but the
sentences are Claude's, not transcriptions. A later pass expanded the
anaphora/anamorphism detour from one clause into a full paragraph, again on
request, copying the fold/unfold crossover out of the Gemini transcript. Then
this section was written — and promptly made inaccurate by one more request,
which inserted the "From sentence to repository" section above it,
reconstructed not from the transcripts but from the git log and the
repository's own contents.

A document about a self-applying rule, ghost-written by the machine the rule
runs on, closing with an account of its own construction — the traveler, it
turns out, is in here too.
