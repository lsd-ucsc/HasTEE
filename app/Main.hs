{-# LANGUAGE CPP #-}
{-# LANGUAGE DataKinds #-}

module Main where

import Control.Monad.IO.Class(liftIO)

import GHC
import GHC.Paths (libdir)
import DynFlags (defaultLogAction)

import App
import DCLabel
#ifdef ENCLAVE
import Enclave
#else
import Client
#endif


main =
  defaultErrorHandler defaultLogAction $ do
    runGhc (Just libdir) $ do
      dflags <- getSessionDynFlags
      setSessionDynFlags dflags
      target <- guessTarget "test_main.hs" Nothing
      setTargets [target]
      load LoadAllTargets