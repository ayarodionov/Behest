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

(* Small integers hit ties, zeros and negatives, where meaning differs. *)
let small =
  QCheck.(
    set_print Print.(list float)
      (list_of_size Gen.(1 -- 8) (map float_of_int (int_range (-5) 5))))

let implementations_agree =
  QCheck.Test.make ~name:"implementations agree" ~count:1000 small (fun xs ->
      (* [=] treats 0. and -0. as equal; use Float.equal if the contract does not. *)
      median xs = Ok (alt_median xs))

let () = QCheck_base_runner.run_tests_main [ implementations_agree ]
