# g-rec

## Prompt used to define the skill

Invoked as `/y-skill` with these arguments:

> /y-skill g-rec to compute G(n) for a whole number n from 0 upwards: G(0) = 2,
> G(1) = 1. Answers those cases directly. For n of 2 or more,
> G(n) = 3 * G(n - 1) - G(n - 2) + 1. Do not work these values yourself,
> consult the supporting file once case n - 1 and once again on case n - 2,
> then compute the anwser. Reply with number only

## Math recursion

$$
G(n) =
\begin{cases}
2 & \text{if } n = 0 \\
1 & \text{if } n = 1 \\
3\,G(n-1) - G(n-2) + 1 & \text{if } n \ge 2
\end{cases}
$$

First values: G(0)=2, G(1)=1, G(2)=2, G(3)=6, G(4)=17.

## OCaml code

```ocaml
let rec g n =
  if n = 0 then 2
  else if n = 1 then 1
  else 3 * g (n - 1) - g (n - 2) + 1
```

---

## Note on the examples below

`g-rec` is a *tree* recursion: each step consults two smaller cases
(`n-1` and `n-2`), so the number of consultations grows exponentially —
G(4) already spawned 8 base-case lookups. That is expensive in tokens and
awkward to trace.

The recursions below are all **linear** (each step consults exactly one
smaller case, `n-1`), so computing at `n` is a single chain of `n`
consultations. That keeps the token count linear and makes the trace a
readable ladder you can step through to localize a bug. They also avoid
textbook sequences (factorial, Fibonacci, powers of two) whose first terms
a model can recite from memory instead of actually recursing.

# s-rec

## Prompt used to define the skill

> /y-skill s-rec to compute S(n) for a whole number n from 0 upwards: S(0) = 5.
> Answer that case directly. For n of 1 or more, S(n) = 2 * S(n - 1) - 3.
> Do not work these values yourself, consult the supporting file once on
> case n - 1, then compute the answer. Reply with number only

## Math recursion

$$
S(n) =
\begin{cases}
5 & \text{if } n = 0 \\
2\,S(n-1) - 3 & \text{if } n \ge 1
\end{cases}
$$

First values: 5, 7, 11, 19, 35, 67, 131. An affine map; values grow
geometrically but the consultation chain stays linear. Good contrast with
`g-rec`: same flavour, no branching.

## OCaml code

```ocaml
let rec s n =
  if n = 0 then 5
  else 2 * s (n - 1) - 3
```

# q-rec

## Prompt used to define the skill

> /y-skill q-rec to compute Q(n) for a whole number n from 0 upwards: Q(0) = 4.
> Answer that case directly. For n of 1 or more, Q(n) = Q(n - 1) + 2 * n + 1.
> Do not work these values yourself, consult the supporting file once on
> case n - 1, then compute the answer. Reply with number only

## Math recursion

$$
Q(n) =
\begin{cases}
4 & \text{if } n = 0 \\
Q(n-1) + 2n + 1 & \text{if } n \ge 1
\end{cases}
$$

First values: 4, 7, 12, 19, 28, 39, 52 (closed form $n^2 + 2n + 4$). The
step depends on the index `n`, not just the previous value — a common
source of off-by-one bugs.

## OCaml code

```ocaml
let rec q n =
  if n = 0 then 4
  else q (n - 1) + 2 * n + 1
```

# z-rec

## Prompt used to define the skill

> /y-skill z-rec to compute Z(n) for a whole number n from 0 upwards: Z(0) = 1.
> Answer that case directly. For n of 1 or more, Z(n) = n - 2 * Z(n - 1).
> Do not work these values yourself, consult the supporting file once on
> case n - 1, then compute the answer. Reply with number only

## Math recursion

$$
Z(n) =
\begin{cases}
1 & \text{if } n = 0 \\
n - 2\,Z(n-1) & \text{if } n \ge 1
\end{cases}
$$

First values: 1, -1, 4, -5, 14, -23, 52. The sign flips every step, so a
wrong coefficient or a dropped minus corrupts the trace visibly — exactly
the kind of mistake the buggy `- 2 * g (n - 2)` was. Good for debugging
practice.

## OCaml code

```ocaml
let rec z n =
  if n = 0 then 1
  else n - 2 * z (n - 1)
```
