module Results where

import Data.Monoid
import Data.Map.Strict (Map, empty, unionWith, fromListWith)
import qualified Data.Map.Strict as Map

--import TermGen

data Histogram a = Histogram (Map a Int)
  deriving (Show, Read)

instance (Ord a) => Monoid (Histogram a) where
  mempty = Histogram empty
  Histogram a `mappend` Histogram b = Histogram $ unionWith (+) a b

makeHistogram l = Histogram $ fromListWith (+) $ zip l (repeat 1)

data RunTime = RunTime Integer Integer
  deriving (Show, Read)

instance Monoid RunTime where
  mempty = RunTime 0 0
  RunTime a b `mappend` RunTime c d = RunTime (a + c) (b + d)

data TimingInfo = TimingInfo {
  genTime   :: RunTime,
  childTime :: RunTime
  }
  deriving (Show, Read)

instance Monoid TimingInfo where
  mempty = TimingInfo mempty mempty
  TimingInfo a1 b1 `mappend` TimingInfo a2 b2 =
    TimingInfo (a1 `mappend` a2) (b1 `mappend` b2)

data ResultsHist = ResultsHist {
  histAll :: Map Int Int,
  histCtr :: Map Int Int
  }
  deriving (Show, Read)

mergeHist a b = Map.unionWith (+) a b

instance Monoid ResultsHist where
  mempty = ResultsHist Map.empty Map.empty
  ResultsHist c1 d1 `mappend` ResultsHist c2 d2 =
    ResultsHist (c1 `mergeHist` c2) (d1 `mergeHist` d2)
