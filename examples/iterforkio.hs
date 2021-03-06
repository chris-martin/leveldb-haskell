{-# LANGUAGE    OverloadedStrings        #-}
{-# OPTIONS_GHC -fno-warn-unused-do-bind #-}

-- |
-- Simplistic demo of 'Iterator' synchronization, using the 'Base" API
--
module Main where

import Control.Concurrent
import Control.Concurrent.Async
import Data.Default

import Database.LevelDB.Base

import qualified Data.ByteString.Char8 as BS

main :: IO ()
main = withDB "/tmp/leveltest" def{ createIfMissing = True } $ \ db -> do

    let xs = [1..100] :: [Int]

    write db def (map (\ x -> Put (BS.pack . show $ x) "") xs)

    withIter db def $ \ iter -> do
        _   <- iterFirst iter
        lck <- newMVar iter
        es  <- mapConcurrently (getEntry lck) xs
        mapM (\ (i,e) -> putStrLn $ "#" ++ show i ++ ": " ++ show e) es

    return ()
  where
    getEntry lck i = withMVar lck $ \ iter -> do
        entry <- iterEntry iter
        iterNext iter
        return (i, entry)
