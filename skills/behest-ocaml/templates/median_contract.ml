(* behest-effects: io *)
(* Contract for [Median.median]. Approved by the human; do not edit to make a build pass.
   (The test runner itself prints, so this file declares io; the module under test
   is scanned separately and should declare none.) *)

open Median

(* --- examples ---------------------------------------------------------------- *)

let examples =
  [ ("odd length: the middle value", median [ 3.; 1.; 2. ] = Ok 2.)
  ; ("even length: mean of the middle two", median [ 1.; 2. ] = Ok 1.5)
  ; ("ties", median [ 0.; 0. ] = Ok 0.)
  ; ("single element", median [ 5. ] = Ok 5.)
  ; ("negatives", median [ 0.; -1. ] = Ok (-0.5))
  ; ("odd length of five: still the middle value", median [ 5.; 1.; 4.; 2.; 3. ] = Ok 3.)
    (* Answer to an open question: an empty list is an error, not a default. *)
  ; ("empty is an error", median [] = Error Empty)
    (* Answer to an open question: NaN is rejected, not skipped or propagated. *)
  ; ("NaN is an error", median [ 1.; Float.nan ] = Error Not_a_number)
    (* Boundary: the mean of two huge values must not overflow to infinity. *)
  ; ("no overflow", median [ 1.7e308; 1.7e308 ] = Ok 1.7e308)
  ; ("no overflow (negative)", median [ -1.7e308; -1.7e308 ] = Ok (-1.7e308))
  ]

(* --- properties ---------------------------------------------------------------- *)

(* Include huge values on purpose: plain random floats rarely reach them. *)
let number =
  QCheck.(oneof [ float_range (-1e6) 1e6; oneofl [ 1.7e308; -1.7e308; 0.; -0. ] ])

(* QCheck's list shrinker can shrink below the minimum size, so the properties
   discard the empty list with [assume]. *)
let numbers =
  QCheck.(set_print Print.(list float) (list_of_size Gen.(1 -- 12) number))

let order_does_not_matter =
  QCheck.Test.make ~name:"order does not matter" ~count:500 numbers (fun xs ->
      QCheck.assume (xs <> []);
      median xs = median (List.rev xs))

let between_min_and_max =
  QCheck.Test.make ~name:"is between min and max" ~count:500 numbers (fun xs ->
      QCheck.assume (xs <> []);
      match median xs with
      | Ok m ->
          List.fold_left Float.min Float.infinity xs <= m
          && m <= List.fold_left Float.max Float.neg_infinity xs
      | Error _ -> false)

(* Pins the position: without this, any fixed position (the first third, say)
   would pass the two properties above. *)
let half_below_half_above =
  QCheck.Test.make ~name:"half at or below, half at or above" ~count:500 numbers (fun xs ->
      QCheck.assume (xs <> []);
      match median xs with
      | Ok m ->
          let n = List.length xs in
          let count p = List.length (List.filter p xs) in
          2 * count (fun x -> x <= m) >= n && 2 * count (fun x -> x >= m) >= n
      | Error _ -> false)

(* --- runner -------------------------------------------------------------------- *)

let () =
  let bad = List.filter (fun (_, ok) -> not ok) examples in
  List.iter (fun (name, _) -> prerr_endline ("FAILED example: " ^ name)) bad;
  if bad <> [] then exit 1;
  QCheck_base_runner.run_tests_main [ order_does_not_matter; between_min_and_max; half_below_half_above ]
