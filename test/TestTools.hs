{-# LANGUAGE ScopedTypeVariables #-}
module TestTools where

import System.Posix.Signals (raiseSignal, Signal)
import Data.Maybe (fromJust)
import qualified Control.Exception as Ex
import Control.Applicative ((<$>), (<|>))
import Test.HUnit (Assertion, assertBool, assertFailure)

-- | Check that the given IO action raises the specified exception
assertRaises :: (Ex.Exception e, Eq e, Show e)
             => String      -- ^ Message displayed if assertion fails
             -> (e -> Bool) -- ^ Expected exception
             -> IO a        -- ^ Action to run
             -> Assertion
assertRaises msg checkEx p = do
  mex <- Ex.try p
  case mex of
    Right _  -> assertFailure (msg ++ ": No exception was raised")
    Left ex ->
      case Ex.fromException ex of
        Just ex' -> assertBool (msg ++ ": Got the wrong exception: " ++ show ex') (checkEx ex')
        Nothing  -> assertFailure $ msg ++ ": "
                                  ++ "Raised exception of the wrong type "
                                  ++ exceptionType ex ++ ": "
                                  ++ show ex

-- | Find the type of an exception (only a few kinds of exceptions are supported)
exceptionType :: Ex.SomeException -> String
exceptionType ex = fromJust $
      ((\(_ :: Ex.IOException)    -> "IOException")       <$> Ex.fromException ex)
  <|> ((\(_ :: Ex.AsyncException) -> "AsyncException")    <$> Ex.fromException ex)
  <|> ((\(_ :: Ex.ErrorCall)      -> "ErrorCall")         <$> Ex.fromException ex)
  <|> Just "Unknown type"

-- | Like 'raiseSignal', but with a more general type
throwSignal :: Signal -> IO a
throwSignal signal = raiseSignal signal >> undefined
