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

let () =
  if Array.length Sys.argv <> 3 then begin
    prerr_endline "usage: oracle <skill> <n>"; exit 2
  end;
  let name = Sys.argv.(1) and n = int_of_string Sys.argv.(2) in
  let v =
    match name with
    | "g-rec"   -> g n
    | "s-rec"   -> s n
    | "q-rec"   -> q n
    | "z-rec"   -> z n
    | "collatz" -> c n
    | other     -> prerr_endline ("unknown skill: " ^ other); exit 2
  in
  print_int v; print_newline ()
