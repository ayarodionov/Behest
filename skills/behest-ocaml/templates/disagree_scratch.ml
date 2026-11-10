(* behest-effects: io *)
(* Disagreement check (scratch file: never commit, never approve).
   Add it as a second test executable next to median.ml and run it.

   QCheck shrinks a failure to a minimal input and prints it; show that input and
   both answers to the human. Each one is a missing example. The alternative must
   pass the approved contract first. Delete this file when done. *)

open Median

(* The alternative: deliberately different (another algorithm, or the other
   plausible reading of the request). *)
let alt_median xs =
  let a = Array.of_list xs in
  Array.sort compare a;
  a.((Array.length a - 1) / 2) (* lower middle value *)

(* Small integers hit ties, zeros and negatives, where meaning differs.
   QCheck's list shrinker can shrink below the minimum size (to []) and, removing one
   element at a time, flips odd/even length and can stop early. This shrinker keeps
   the list non-empty and also tries removing two neighbours at a time. *)
let small =
  let gen = QCheck.Gen.(list_size (1 -- 8) (map float_of_int (int_range (-5) 5))) in
  let shrink xs yield =
    let n = List.length xs in
    let without skip = List.filteri (fun j _ -> not (skip j)) xs in
    if n > 2 then for i = 0 to n - 2 do yield (without (fun j -> j = i || j = i + 1)) done;
    if n > 1 then for i = 0 to n - 1 do yield (without (fun j -> j = i)) done;
    List.iteri
      (fun i x -> if x <> 0. then yield (List.mapi (fun j y -> if j = i then 0. else y) xs))
      xs
  in
  QCheck.make ~print:QCheck.Print.(list float) ~shrink gen

let implementations_agree =
  QCheck.Test.make ~name:"implementations agree" ~count:1000 small (fun xs ->
      (* [=] treats 0. and -0. as equal; use Float.equal if the contract does not. *)
      median xs = Ok (alt_median xs))

let () = QCheck_base_runner.run_tests_main [ implementations_agree ]
