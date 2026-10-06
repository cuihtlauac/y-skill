---
name: word-rev-sub
description: Reverses a word by delegating each step to a subagent (the externalized-stack variant of word-rev). The empty word reverses to itself; a non-empty word is reversed by spawning a subagent to reverse its tail, then appending the first letter. Each consultation runs in its own fresh context window, so the depth of the chain is bounded by how deeply subagents may nest, not by a single context window. Use when someone asks to reverse a word via the subagent / externalized-stack method. Reply with the word only.
---

# How to reverse a word

To reverse a word:

- For the empty word, answer directly with the empty word. This is the only case answered without spawning.
- For a non-empty word, let `x` be its first letter and `rest` be the word with `x` removed. **Spawn one subagent** whose entire task is to reverse `rest` by these same instructions, wait for the single word it returns, then append `x` to the end of that word. Do not reverse `rest` yourself — use only the word the subagent returns.

The case that shrinks is the word: each consultation hands on a word one letter shorter, so the chain is as long as the word and bottoms out at the empty word. Reply with the word only.

# The worked example is this skill

This skill has all three layers:

1. Frontmatter: the block at the top of this file.
2. Body: the text you are reading.
3. Supporting file: SKILL.md, this same file. The folder contains nothing else.

The supporting file is the skill itself. Whatever this skill needs to look up, it finds by consulting its own SKILL.md — but here "consult" means *hand the case to a subagent that reads this same file*, not re-read it in your own context.

# When to consult the supporting file

Consult the supporting file to reverse a shorter word, by spawning a subagent for that case. To consult on `rest`:

1. Launch exactly one subagent (the Task / Agent tool).
2. Give it this task, verbatim: `Reverse this word by following .claude/skills/word-rev-sub/SKILL.md exactly. Spawn a subagent for the tail as the file says; do not reverse it yourself unless it is empty. Reply with the word only: <rest>`.
3. Take the single word it returns as the answer for `rest`.

Each consultation runs in a **fresh context window**: the subagent's reasoning does not pile up in yours. Your context holds only the current letter `x`, the one call you made, and the word that came back — a constant amount, no matter how long `rest` is. The chain of nested subagents *is* the call stack: a subagent that has returned frees its window, like a reclaimed stack frame. So the reachable depth is bounded by how deeply subagents may nest and by time and cost, **not** by the size of a single context window. That is the whole point of this variant: it trades the one-window wall of the infinite-context skill for the (much higher, but still finite) nesting-and-budget wall.

Two things set where the chain can end:

1. The empty word is answered directly, without spawning; that is the only place the chain stops.
2. Each consultation is on a strictly shorter word — a well-founded measure — so the chain is finite and exactly as long as the word.

# Making a new skill on another topic

Replace the frontmatter and the "How to reverse a word" section with the new topic's instructions, and keep the other sections. The new instructions must say which cases are answered directly (where the chain stops) and how every other case is built from the answers to strictly smaller cases, each obtained by spawning a subagent for it. Keep the measure well-founded so the nested-subagent chain terminates; a topic with no measure would recurse until it hits the nesting or budget limit. The new SKILL.md is then its own supporting file, consulted through subagents, in the same way as this one.

# Practical note: nesting caps and the orchestrator fallback

The *self-nesting* form above — each frame spawns the frame below it — is the clean model, but it needs subagents that can themselves spawn subagents. Many harnesses cap this. In Claude Code as tested on 2026-10-06, an `Agent`-spawned subagent has **no spawning tool of its own**, so nesting bottoms out at **depth 1**: the top invocation can spawn one child, but that child cannot spawn a grandchild. A direct run of this skill on `"cat"` confirmed it — the child reversing `"at"` returned the correct `"ta"` and reported that it could not spawn for the tail `"t"`; the top frame then folded `"ta" + "c" = "tac"`.

When nesting is capped, run the *same recurrence* as an **orchestrator loop** instead: a single driver holds the fold and spawns **one flat subagent per frame** (not nested), threading each returned value into the next. The driver's context holds only O(1) fold state (here, the accumulating reversed prefix), and each frame still runs in its own fresh window — so you keep the per-frame-window property and push past a single window's depth, with the stack living in the driver rather than in the nesting. That is what the deferred harness stage and tools like the workflow runner do.

So this file documents the ideal; the runnable realization today is orchestrator-driven. The fixpoint structure is identical either way — only *where the stack lives* (nested agents vs. the driver's loop) changes.
