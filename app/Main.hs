{-# LANGUAGE CPP #-}
{-# LANGUAGE DataKinds #-}

module Main where

import Control.Monad.IO.Class(liftIO)

import App
import DCLabel
#ifdef ENCLAVE
import Enclave
#else
import Client
#endif

import GHC
import GHC.Paths ( libdir )
import DynFlags ( defaultFatalMessager, defaultFlushOut )

main :: IO SuccessFlag
main =
    defaultErrorHandler defaultFatalMessager defaultFlushOut $ do
      runGhc (Just libdir) $ do
        dflags <- getSessionDynFlags
        _ <- setSessionDynFlags dflags
        target <- guessTarget "test_main.hs" Nothing
        setTargets [target]
        load LoadAllTargets