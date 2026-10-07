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

# word-rev

The examples above are all numeric, but the combinator is not about numbers —
it is about *self-reference over a shrinking case*. Here the shrinking case is a
**word**, not an integer: each consultation hands on a word one letter shorter,
the chain is as long as the word, and it bottoms out at the empty word. The
answer folded back up is itself a word. Same machinery, non-numeric data.

## Prompt used to define the skill

> /y-skill word-rev to reverse a word. The empty word reverses to itself; answer
> that case directly. For a non-empty word, consult the supporting file once on
> the word with its first letter removed, then append that first letter to the
> end of the word the consultation returns. Do not reverse the smaller word
> yourself. Reply with the word only

## Structural recursion

$$
\mathrm{rev}(w) =
\begin{cases}
\varepsilon & \text{if } w = \varepsilon \\
\mathrm{rev}(x_2 x_3 \ldots x_k)\,x_1 & \text{if } w = x_1 x_2 \ldots x_k
\end{cases}
$$

The measure is $|w|$, the length of the word, which strictly decreases at every
step — so the topic is well-founded (the μ / inductive case) and always
terminates. Examples: `rev("stressed") = "desserts"`, `rev("level") = "level"`.

## OCaml code

```ocaml
let rec rev s =
  let len = String.length s in
  if len = 0 then ""
  else rev (String.sub s 1 (len - 1)) ^ String.make 1 s.[0]
```

# ski-eval

The universal one. The examples above each compute *one* function; this skill
normalizes terms of **SK combinatory logic with native integers**, a
Turing-complete rewrite system — so this single child of the combinator can
compute *any* computable function, given the right term. It is the native
universality proof of `PROOF.md`: pure SK carries the theorem; the δ-rules
(native numerals with `add`, `sub`, `mul`, `eq`, `cond`) are the standard
conservative sugar of Plotkin's PCF and Turner's SK reduction machines
(SASL/Miranda, 1979), there to keep terms small enough for a stochastic
interpreter to follow. `Y(f) → f(Y(f))` is a primitive rule — the project's
own object, as one line of the machine it powers.

## Prompt used to define the skill

> /y-skill ski-eval to normalize a term of SK combinatory logic with native
> integers. Terms are built from the atoms S, K, I, B, C, Y, T, F, add, sub,
> mul, eq, cond and integer numerals by application written f(x). The rules:
> S(x)(y)(z) → x(z)(y(z)); K(x)(y) → x; I(x) → x; B(x)(y)(z) → x(y(z));
> C(x)(y)(z) → x(z)(y); Y(f) → f(Y(f)); add/sub/mul/eq fire only on two
> numerals; cond(T)(x)(y) → x, cond(F)(x)(y) → y. A term in normal form is
> answered directly. Otherwise perform exactly one leftmost-outermost rewrite
> (strict primitives first reduce the argument they need) and consult the
> supporting file once on the resulting term. Reply with the term only

## Shape of the recursion

One rewrite per consultation, so the chain length is the number of reduction
steps. `Y(f) → f(Y(f))` grows the term, so there is **no well-founded
measure** — like `collatz`, a chain may run forever, and under the
infinite-context hypothesis that is permitted. Termination is a property of
the *term*, exactly as the README says it is a property of the topic.

First values (each `→*` is one consultation chain):

    I(42)                 →* 42
    S(K)(K)(7)            →* 7          (S K K = I)
    add(mul(2)(3))(1)     →* 7          (δ-rules + strictness)
    cond(eq(1)(2))(0)(9)  →* 9
    mul(6)(7)             →* 42         (the Answer; and the negative control
                                         checks that mul(6)(9), the famously
                                         wrong question, is rejected)

The flagship: `s-rec` compiled to combinators by bracket abstraction
(mechanically — see the note below), then run as a *program* on this evaluator:

    Y(B(S(C(B(cond)(C(eq)(0)))(5)))(C(B(C)(B(B(sub))(B(B(mul(2)))(C(B)(C(sub)(1))))))(3)))(6)  →*  131

which matches the `s-rec 6 131` baseline — the same oracle grades the
recurrence computed directly by `/s-rec` and computed as a program by the
universal evaluator.

## OCaml code

The normal-order SK+δ normalizer lives in `harness/oracle.ml` (type `sk`,
functions `ski_parse` / `ski_step` / `ski_normalize` / `ski_print`); it is
fuel-bounded because Y-terms may diverge. The `s-rec` program above was
generated, not hand-derived: a ~50-line bracket-abstraction compiler
(S, K, I, B, C with η) applied to

```ocaml
(* s = Y (fun f n -> if n = 0 then 5 else 2 * f (n - 1) - 3) *)
```

and verified against the oracle (`s(0)=5`, `s(3)=19`, `s(6)=131`).
