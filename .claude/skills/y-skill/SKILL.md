---
name: y-skill
description: Explains how to write an Agent Skill (a folder with a SKILL.md file), using this skill as the worked example. Given a name and a topic as arguments, creates a new skill on that topic built the same way. Use when someone asks how to write, structure, check or copy a skill, or wants a new skill built like this one.
---

# How to write a skill

If you were given arguments, they ask for a new skill: the first word is the new skill's name and the rest is its topic. Make it as the section "Making a new skill on another topic" says, save it in this project as `.claude/skills/<name>/SKILL.md`, and confirm that its kept sections are word for word the same as this file's. With no arguments, explain how to write a skill using the three layers below.

A skill is a folder. Its entry point is a file named SKILL.md, and it has three layers:

1. Frontmatter: the block between two lines of three dashes at the top of SKILL.md. It holds a `name` and a `description`. The description is the only part read before the skill is chosen, so it must say what the skill does and when to use it.
2. Body: everything in SKILL.md after the frontmatter. These are the instructions followed once the skill is loaded. Keep them direct, ordered, and short enough to read in full.
3. Supporting files: files the body names and says when to open, so they are read only when needed.

# The worked example is this skill

This skill has all three layers:

1. Frontmatter: the block at the top of this file.
2. Body: the text you are reading.
3. Supporting file: SKILL.md, this same file. The folder contains nothing else.

The supporting file is the skill itself. Whatever this skill needs to look up, it finds by consulting its own SKILL.md.

# When to consult the supporting file

Consult the supporting file only to answer a smaller case of the task in front of you, and only when the instructions above require that case. To consult it on a case, read it as if you had been handed only that case, and use the answer you get. Two rules keep this finite:

1. Every consultation is on a strictly smaller case than the one you are working on.
2. The smallest cases are answered directly, without consulting the file.

Explaining how to write a skill is answered directly: the three layers listed above are the answer, so do not consult the file for it. The same holds for checking a skill someone wrote (compare its layers with this file's) and for copying this skill (copy this one file).

# Making a new skill on another topic

Replace the frontmatter and the section "How to write a skill" with the new topic's instructions, and keep the other sections. The new instructions must say which cases are answered directly and how every other case is built from answers to smaller cases. The new SKILL.md is then its own supporting file, in the same way as this one.
