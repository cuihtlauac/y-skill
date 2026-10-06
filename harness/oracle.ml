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

let () =
  if Array.length Sys.argv <> 3 then begin
    prerr_endline "usage: oracle <skill> <arg>"; exit 2
  end;
  let name = Sys.argv.(1) and arg = Sys.argv.(2) in
  let num () = int_of_string arg in  (* numeric skills parse the arg on demand *)
  let out =
    match name with
    | "g-rec"    -> string_of_int (g (num ()))
    | "s-rec"    -> string_of_int (s (num ()))
    | "q-rec"    -> string_of_int (q (num ()))
    | "z-rec"    -> string_of_int (z (num ()))
    | "collatz"  -> string_of_int (c (num ()))
    | "word-rev" -> rev arg
    | other      -> prerr_endline ("unknown skill: " ^ other); exit 2
  in
  print_string out; print_newline ()
