;; behest-effects: none
;;
;; Contract for `median`. Approved by the human; do not edit to make a build pass.
(ns median-contract-test
  (:require [clojure.test :refer [deftest is]]
            [clojure.test.check.clojure-test :refer [defspec]]
            [clojure.test.check.generators :as gen]
            [clojure.test.check.properties :as prop]
            [median :refer [median]]))

;; --- examples ---------------------------------------------------------------

(deftest examples
  (is (= 2.0 (median [3.0 1.0 2.0])))   ; odd length: the middle value
  (is (= 1.5 (median [1.0 2.0])))       ; even length: mean of the middle two
  (is (= 0.0 (median [0.0 0.0])))       ; ties
  (is (= 5.0 (median [5.0])))           ; single element
  (is (= -0.5 (median [0.0 -1.0])))     ; negatives
  (is (= 3.0 (median [5.0 1.0 4.0 2.0 3.0]))))   ; odd length of five: still the middle value

;; Answer to an open question: the result is always a double, even for integer input.
;; (= 2 2.0) is false in Clojure, so this also pins the type.
(deftest result-is-always-a-double
  (is (= 2.0 (median [1 2 3])))
  (is (double? (median [4 4])))
  (is (double? (median [7]))))

;; Answer to an open question: an empty collection is an error, not nil.
(deftest empty-is-an-error
  (is (thrown? clojure.lang.ExceptionInfo (median []))))

;; Answer to an open question: NaN is rejected, not skipped or propagated.
(deftest nan-is-an-error
  (is (thrown? IllegalArgumentException (median [1.0 Double/NaN]))))

;; Boundary: the mean of two huge values must not overflow to Infinity.
(deftest huge-values-do-not-overflow
  (is (= 1.7e308 (median [1.7e308 1.7e308])))
  (is (= -1.7e308 (median [-1.7e308 -1.7e308]))))

;; --- properties ---------------------------------------------------------------

(def numbers
  (gen/vector (gen/double* {:NaN? false :infinite? false}) 1 12))

(defspec order-does-not-matter 200
  (prop/for-all [xs numbers]
    (= (median xs) (median (reverse xs)))))

(defspec between-min-and-max 200
  (prop/for-all [xs numbers]
    (<= (apply min xs) (median xs) (apply max xs))))

;; Pins the position: without this, any fixed position (the first third, say)
;; would pass the two properties above.
(defspec half-at-or-below-and-half-at-or-above 200
  (prop/for-all [xs numbers]
    (let [m (median xs)
          n (count xs)]
      (and (>= (* 2 (count (filter #(<= % m) xs))) n)
           (>= (* 2 (count (filter #(>= % m) xs))) n)))))

(defspec does-not-modify-its-input 200
  (prop/for-all [xs numbers]
    (let [before (vec xs)]
      (median xs)
      (= before xs))))
