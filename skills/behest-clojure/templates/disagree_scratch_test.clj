;; behest-effects: none
;;
;; Disagreement check (scratch file: never commit, never approve).
;; Save as test/disagree_scratch_test.clj and run:
;;
;;     clojure -M:test -e "(require 'disagree-scratch-test) (clojure.test/run-tests 'disagree-scratch-test)"
;;
;; test.check shrinks a failure to a minimal input and prints it; show that input
;; and both answers to the human. Each one is a missing example. The alternative
;; must pass the approved contract first. Delete this file when done.
(ns disagree-scratch-test
  (:require [clojure.test.check.clojure-test :refer [defspec]]
            [clojure.test.check.generators :as gen]
            [clojure.test.check.properties :as prop]
            [median :refer [median]]))

(defn alt-median
  "The alternative: deliberately different (another algorithm, or the other
  plausible reading of the request)."
  [xs]
  (let [s (vec (sort xs))]
    (double (s (quot (dec (count s)) 2)))))   ; lower middle value

;; Small integers hit ties, zeros and negatives, where meaning differs.
(def small-vectors
  (gen/vector (gen/fmap double (gen/choose -5 5)) 1 8))

(defspec implementations-agree 1000
  (prop/for-all [xs small-vectors]
    (let [a (median xs)
          b (alt-median xs)]
      ;; Compare the class as well as the value: (= 1 1.0) is false, (== 1 1.0) is true.
      (and (= (class a) (class b)) (= a b)))))
