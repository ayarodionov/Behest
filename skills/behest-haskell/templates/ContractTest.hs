-- behest-effects: io
--
-- Contract for `median`. Approved by the human; do not edit to make a build pass.
-- (The test runner itself prints, so this file declares `io`; the module under
-- test is scanned separately and should declare `none`.)
module Main (main) where

import Control.Monad (unless)
import Data.List (sort)
import Median (MedianError (..), median)
import System.Exit (exitFailure)
import Test.QuickCheck

-- --- examples ---------------------------------------------------------------

examples :: [(String, Bool)]
examples =
  [ ("odd length: the middle value", median [3, 1, 2] == Right 2)
  , ("even length: mean of the middle two", median [1, 2] == Right 1.5)
  , ("ties", median [0, 0] == Right 0)
  , ("single element", median [5] == Right 5)
  , ("negatives", median [0, -1] == Right (-0.5))
  , -- Answer to an open question: an empty list is an error, not a default.
    ("empty is an error", median [] == Left Empty)
  , -- Answer to an open question: NaN is rejected, not skipped or propagated.
    ("NaN is an error", median [1, 0 / 0] == Left NotANumber)
  , -- Boundary: the mean of two huge values must not overflow to Infinity.
    ("no overflow", median [1.7e308, 1.7e308] == Right 1.7e308)
  , ("no overflow (negative)", median [-1.7e308, -1.7e308] == Right (-1.7e308))
  ]

-- --- properties ---------------------------------------------------------------

-- Include huge values on purpose: plain `arbitrary` rarely reaches them.
number :: Gen Double
number =
  oneof
    [ arbitrary `suchThat` (not . isNaN)
    , elements [1.7e308, -1.7e308, 0, -0.0]
    ]

numbers :: Gen [Double]
numbers = resize 12 (listOf1 number)

prop_order_does_not_matter :: Property
prop_order_does_not_matter =
  forAllShrink numbers shrink $ \xs ->
    forAll (shuffle xs) $ \ys -> median xs === median ys

prop_between_min_and_max :: Property
prop_between_min_and_max =
  forAllShrink numbers shrink $ \xs -> case median xs of
    Right m -> property (minimum xs <= m && m <= maximum xs)
    Left e -> counterexample (show e) False

-- --- runner -------------------------------------------------------------------

main :: IO ()
main = do
  let bad = [name | (name, ok) <- examples, not ok]
  mapM_ (putStrLn . ("FAILED example: " ++)) bad
  r1 <- quickCheckResult prop_order_does_not_matter
  r2 <- quickCheckResult prop_between_min_and_max
  unless (null bad && all isSuccess [r1, r2]) exitFailure
