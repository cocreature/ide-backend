module Main where

-- Cabal
import qualified Paths_ide_backend as Self (version)

import System.FilePath
import System.Directory
import Data.Version
import Data.List
import Data.Maybe
import Text.Printf
import Control.Monad

import Test.Framework (Test, defaultMain, testGroup, buildTest)
import Test.Golden

main :: IO ()
main = defaultMain tests

tests :: [Test]
tests =
  [ testGroup "Compare new test logs with old"
    [ golden ghcErrorsLogName ]
  ]

ghcErrorsLogName :: String
ghcErrorsLogName =
  "ide-backend-" ++ showVersion Self.version ++ "-ghc-errors.log"

oldLogsDir :: String
oldLogsDir = "test/OldLogs"

golden :: String -> Test
golden logName = buildTest $ do
  createDirectoryIfMissing False oldLogsDir
  cnts <- getDirectoryContents oldLogsDir
  let currentLog = "dist/test" </> logName
      oldLogs = reverse $ sort $ filter (isPrefixOf logName) cnts
      goldenLog = maybe currentLog (oldLogsDir </>) $ listToMaybe oldLogs
      msg = "Performing  diff " ++ goldenLog ++ " " ++ currentLog ++ "  "
      test = goldenVsFile msg goldenLog currentLog (return ())
      n :: Int
      n = case tail $ takeExtension goldenLog of
        "log" -> 0
        f     -> read f
      nextExt = printf "%03d" $ n + 1
  goldenLogCnts  <- readFile goldenLog
  currentLogCnts <- readFile currentLog
  -- Checking the equality independently of goldenVsFile, to decide
  -- whether to record a new log version. This is a bit goofy.
  when (goldenLogCnts /= currentLogCnts) $
    copyFile currentLog (oldLogsDir </> logName <.> nextExt)
  return test