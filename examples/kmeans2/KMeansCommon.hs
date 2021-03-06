{-# LANGUAGE DeriveDataTypeable #-}
module KMeansCommon where

import Data.List (foldl')
import Data.Typeable (Typeable)
import Data.Data (Data)
import Remote.Encoding
import Data.Binary
import Data.Array.Unboxed
import qualified Data.ByteString.Lazy as B
import Debug.Trace

data Vector = Vector !(UArray Int Double) deriving (Typeable,Eq)
instance Binary Vector where put (Vector a) = put a
                             get = do a<-get
                                      return $! Vector a

instance Read Vector where
  readsPrec i a = let f = readsPrec i a
              in [(Vector $! listArray (0,99) (fst $ head f),snd $ head f)]

instance Show Vector where
   showsPrec _ (Vector a) = showList $ elems a
  

data Cluster = Cluster
               {
                  clId :: !Int,
                  clCount :: !Int,
                  clSum :: !Vector
               } deriving (Show,Read,Typeable,Eq)
instance Binary Cluster where put (Cluster a b c) = put a>>put b>>put c
                              get = do a<-get
                                       b<-get
                                       c<-get
                                       return $ Cluster a b c

clusterCenter :: Cluster -> Vector
clusterCenter cl = let (Vector arr) = clSum cl
                       count = fromIntegral $ clCount cl
                       newelems = case count of
                                     0 -> replicate 100 0
                                     _ -> map (\d -> d / count) (elems arr)
                    in Vector $ listArray (bounds arr) newelems

sqDistance :: Vector -> Vector -> Double
sqDistance (Vector a1) (Vector a2) = sum $ map (\(a,b) -> let dif = a-b in dif*dif) (zip (elems a1) (elems a2))

{-
makeCluster :: Int -> [Vector] -> Cluster
makeCluster clid vecs = Cluster {clId = clid, clCount = length vecs, clSum = vecsum}
   where vecsum = Vector sumArray
         sumArray = listArray (0,99) [ sum $ map ((flip(!))i) (map unVector vecs) | i<-[0..99] ]
         unVector (Vector x) = x
-}
makeCluster :: Int -> [Vector] -> Cluster
makeCluster clid vecs = Cluster {clId = clid, clCount = length vecs, clSum = vecsum}
   where vecsum = Vector sumArray
         sumArray = listArray (0,99) [ sum $ map ((flip(!))i) (map unVector vecs) | i<-[0..99] ]
         unVector (Vector x) = x


addCluster :: Cluster -> Cluster -> Cluster
addCluster (Cluster aclid acount asum) (Cluster bclid bcount bsum) = Cluster aclid (acount+bcount) (addVector asum bsum)
addVector :: Vector -> Vector -> Vector
addVector (Vector a ) (Vector b) = Vector $! listArray (bounds a) (map (\(a,b) -> a+b) (zip (elems a) (elems b)))
zeroVector :: Vector -> Vector
zeroVector (Vector a) = Vector $! listArray (bounds a) (repeat 0)

getPoints :: FilePath -> IO [Vector]
getPoints fp = do c <- readFile fp
                  return $ read c

getClusters :: FilePath -> IO [Cluster]
getClusters fp = do c <- readFile fp
                    return $ read c


