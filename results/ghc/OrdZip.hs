module OrdZip where

import Control.Monad (forM_)

--ordZipWith :: Ord a => (b -> c -> d) -> [(a, b)] -> [(a, c)] -> [(a, d)]
--ordZipWith

myZip :: [(Int, Int)] -> [Int] -> [(Int, Int)]
myZip []         []     = []
myZip xs         []     = xs
myZip []         js     = zip js (repeat 0)
myZip ((i,v):xs) (j:js)
  | i <  j    = (i,v):myZip xs (j:js)
  | i == j    = (i,v):myZip xs js
  | otherwise = (j,0):myZip ((i,v):xs) js

printForGnuplot :: Int -> [(Int, Int)] -> String
printForGnuplot n l =
  concat [ show i ++ " " ++ show n ++ "\n"
         | (i, n) <- myZip l [1..n] ]
