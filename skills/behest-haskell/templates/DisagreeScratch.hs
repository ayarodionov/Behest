-- behest-effects: io
--
-- Disagreement check (scratch file: never commit, never approve).
-- Save as DisagreeScratch.hs next to Median.hs and run:
--
--     runghc DisagreeScratch.hs
--
-- QuickCheck shrinks a failure to a minimal input and prints it; show that input
-- and both answers to the human. Each one is a missing example. The alternative
-- must pass the approved contract first. Delete this file when done.
module Main (main) where

import Data.List (sort)
import Median (median) -- the function under test
import System.Exit (exitFailure)
import Test.QuickCheck

-- | The alternative: deliberately different (another algorithm, or the other
-- plausible reading of the request).
altMedian :: [Double] -> Either String Double
altMedian [] = Left "empty"
altMedian xs = Right (sort xs !! ((length xs - 1) `div` 2)) -- lower middle value

-- Small integers hit ties, zeros and negatives, where meaning differs.
small :: Gen [Double]
small = resize 8 (listOf1 (fromIntegral <$> choose (-5 :: Int, 5)))

prop_agree :: Property
prop_agree = forAllShrink small shrink $ \xs ->
  -- Compare the values only; map the error type if the contract needs it.
  fmap Just (either (const Nothing) Just (median xs))
    === fmap Just (either (const Nothing) Just (altMedian xs))

main :: IO ()
main = do
  r <- quickCheckWithResult stdArgs {maxSuccess = 1000} prop_agree
  if isSuccess r then putStrLn "no disagreement found" else exitFailure
