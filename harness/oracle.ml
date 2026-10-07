(* Reference oracle for the recurrence skills. Ground truth for the harness.
   Usage:  opam exec -- ocaml harness/oracle.ml <skill> <n>
   Prints the integer value, or exits non-zero on a bad argument. *)

let rec g n = if n = 0 then 2 else if n = 1 then 1 else 3 * g (n-1) - g (n-2) + 1
let rec s n = if n = 0 then 5 else 2 * s (n-1) - 3
let rec q n = if n = 0 then 4 else q (n-1) + 2*n + 1
let rec z n = if n = 0 then 1 else n - 2 * z (n-1)
(* Collatz stopping time: T(1)=0, even -> 1+T(n/2), odd>1 -> 1+T(3n+1).
   Not structurally decreasing (the Collatz conjecture); terminates for every
   tested n but there is no proof it does for all. *)
let rec c n = if n = 1 then 0 else if n mod 2 = 0 then 1 + c (n/2) else 1 + c (3*n + 1)

(* Word reversal: a non-numeric recurrence. The shrinking case is the word,
   not a number — rev "" = "", rev (x::xs) = rev xs ^ x. *)
let rec rev s =
  let len = String.length s in
  if len = 0 then "" else rev (String.sub s 1 (len - 1)) ^ String.make 1 s.[0]

(* SK combinatory logic with native integers (ski-eval). Atoms S K I B C Y,
   booleans T F, strict primitives add sub mul eq cond, integer numerals;
   application written f(x). Normal-order (leftmost-outermost) reduction with
   delta-strictness; fuel-bounded, since Y-terms may diverge. *)
type sk = SAtom of string | SNum of int | SApp of sk * sk

let ski_atoms = ["S";"K";"I";"B";"C";"Y";"T";"F";"add";"sub";"mul";"eq";"cond"]

let ski_parse s =
  let n = String.length s in
  let pos = ref 0 in
  let fail m = prerr_endline ("ski-eval parse error: " ^ m); exit 2 in
  let peek () = if !pos < n then Some s.[!pos] else None in
  let is_digit c = '0' <= c && c <= '9' in
  let is_letter c = ('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z') in
  let rec term () =
    let t = ref (primary ()) in
    while peek () = Some '(' do
      incr pos;
      let a = term () in
      (match peek () with Some ')' -> incr pos | _ -> fail "expected )");
      t := SApp (!t, a)
    done;
    !t
  and primary () =
    match peek () with
    | Some '(' ->
      incr pos;
      let t = term () in
      (match peek () with Some ')' -> incr pos | _ -> fail "expected )");
      t
    | Some c when c = '-' || is_digit c ->
      let st = !pos in
      incr pos;
      while (match peek () with Some d -> is_digit d | None -> false) do incr pos done;
      let lit = String.sub s st (!pos - st) in
      if lit = "-" then fail "expected digits after '-'";
      SNum (int_of_string lit)
    | Some c when is_letter c ->
      let st = !pos in
      while (match peek () with Some d -> is_letter d | None -> false) do incr pos done;
      let a = String.sub s st (!pos - st) in
      if List.mem a ski_atoms then SAtom a else fail ("unknown atom " ^ a)
    | _ -> fail "unexpected character"
  in
  let t = term () in
  if !pos <> n then fail "trailing input";
  t

let ski_app h args = List.fold_left (fun t a -> SApp (t, a)) h args

let rec ski_spine t args =
  match t with SApp (f, a) -> ski_spine f (a :: args) | h -> (h, args)

let rec ski_step t =
  let h, args = ski_spine t [] in
  match h, args with
  | SAtom "I", x :: r -> Some (ski_app x r)
  | SAtom "K", x :: _ :: r -> Some (ski_app x r)
  | SAtom "S", x :: y :: z :: r -> Some (ski_app (SApp (SApp (x, z), SApp (y, z))) r)
  | SAtom "B", x :: y :: z :: r -> Some (ski_app (SApp (x, SApp (y, z))) r)
  | SAtom "C", x :: y :: z :: r -> Some (ski_app (SApp (SApp (x, z), y)) r)
  | SAtom "Y", f :: r -> Some (ski_app (SApp (f, SApp (SAtom "Y", f))) r)
  | SAtom ("add" | "sub" | "mul" | "eq" as op), a :: b :: r ->
    (match a, b with
     | SNum m, SNum n ->
       let v = match op with
         | "add" -> SNum (m + n)
         | "sub" -> SNum (m - n)
         | "mul" -> SNum (m * n)
         | _ -> SAtom (if m = n then "T" else "F")
       in
       Some (ski_app v r)
     | SNum _, _ ->
       (match ski_step b with
        | Some b' -> Some (ski_app h (a :: b' :: r))
        | None -> ski_step_args h args)
     | _ ->
       (match ski_step a with
        | Some a' -> Some (ski_app h (a' :: b :: r))
        | None -> ski_step_args h args))
  | SAtom "cond", c :: x :: y :: r ->
    (match c with
     | SAtom "T" -> Some (ski_app x r)
     | SAtom "F" -> Some (ski_app y r)
     | _ ->
       (match ski_step c with
        | Some c' -> Some (ski_app h (c' :: x :: y :: r))
        | None -> ski_step_args h args))
  | _ -> ski_step_args h args

and ski_step_args h args =
  let rec go acc = function
    | [] -> None
    | a :: rest ->
      (match ski_step a with
       | Some a' -> Some (ski_app h (List.rev_append acc (a' :: rest)))
       | None -> go (a :: acc) rest)
  in
  go [] args

let ski_normalize t0 =
  let t = ref t0 and fuel = ref 100000 and running = ref true in
  while !running do
    match ski_step !t with
    | Some t' ->
      decr fuel;
      if !fuel <= 0 then begin
        prerr_endline "ski-eval: step budget exhausted (term may diverge)";
        exit 2
      end;
      t := t'
    | None -> running := false
  done;
  !t

let rec ski_print = function
  | SAtom a -> a
  | SNum n -> string_of_int n
  | SApp (f, a) -> ski_print f ^ "(" ^ ski_print a ^ ")"

let () =
  if Array.length Sys.argv <> 3 then begin
    prerr_endline "usage: oracle <skill> <arg>"; exit 2
  end;
  let name = Sys.argv.(1) and arg = Sys.argv.(2) in
  (* numeric skills parse the arg on demand *)
  let num () =
    match int_of_string_opt arg with
    | Some n -> n
    | None -> prerr_endline ("not a number: " ^ arg); exit 2
  in
  let out =
    match name with
    | "g-rec"    -> string_of_int (g (num ()))
    | "s-rec"    -> string_of_int (s (num ()))
    | "q-rec"    -> string_of_int (q (num ()))
    | "z-rec"    -> string_of_int (z (num ()))
    | "collatz"  ->
      let n = num () in
      if n < 1 then (prerr_endline "collatz: the argument must be >= 1"; exit 2);
      string_of_int (c n)
    | "word-rev" -> rev arg
    | "ski-eval" -> ski_print (ski_normalize (ski_parse arg))
    | other      -> prerr_endline ("unknown skill: " ^ other); exit 2
  in
  print_string out; print_newline ()
