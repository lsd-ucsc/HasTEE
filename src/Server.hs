{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE ScopedTypeVariables, RankNTypes, TypeApplications #-}
{-# OPTIONS_GHC -Wno-missing-methods #-}
{-# OPTIONS_GHC -Wno-incomplete-uni-patterns #-}
{-# OPTIONS_GHC -Wno-redundant-constraints #-}
module Server(module Server) where

import Control.Monad
import Control.Monad.IO.Class
import Control.Monad.Trans.State.Strict
import Data.Binary(Binary, encode, decode)
import Data.ByteString.Lazy(ByteString)
import Data.IORef
import Network.Simple.TCP
import System.IO(hFlush, stdout)
import App

import qualified Data.ByteString.Lazy as B

type Ref a = IORef a
newtype Server a = Server (IO a)

instance Functor (Server) where
  fmap f (Server x) = Server $ fmap f x

instance Applicative Server where
  pure x = Server (pure x)
  Server f <*> Server a = Server $ f <*> a

instance Monad Server where
  return = pure
  Server ma >>= k = Server $ do
    a <- ma
    let Server ka = k a
    ka


data Remote a = RemoteDummy

serverConstant :: a -> App (Server (Sec H a))
serverConstant = return . return . sec

liftNewRef :: a -> App (Ref (Sec H a))
liftNewRef a = do
  r <- liftIO $ newIORef (sec a)
  return r

newRef :: a -> Server (Ref (Sec H a))
newRef x = Server $ newIORef $ sec x

readRef :: Ref (Sec H a) -> Server (Sec H a)
readRef ref = Server $ readIORef ref

writeRef :: Ref (Sec H a) -> a -> Server ()
writeRef ref v = Server $ writeIORef ref (sec v)

remote :: (Remotable a) => a -> App (Remote a)
remote f = App $ do
  (next_id, remotes) <- get
  put (next_id + 1, (next_id, \bs -> let Server n = mkRemote f bs in n) : remotes)
  return RemoteDummy

(<.>) :: Binary a => Remote (a -> b) -> a -> Remote b
(<.>) = error "Access to client not allowed"


class Remotable a where
  mkRemote :: a -> ([ByteString] -> Server ByteString)

instance (Binary a) => Remotable (Server a) where
  mkRemote m = \_ -> fmap encode m

instance (Binary a, Remotable b) => Remotable (a -> b) where
  mkRemote f = \(x:xs) -> mkRemote (f $ decode x) xs

data Client a = ClientDummy deriving (Functor, Applicative, Monad, MonadIO)

runClient :: Client a -> App Done
runClient _ = return Done

onServer :: (Binary a) => Remote (Server a) -> Client a
onServer _ = ClientDummy

{-@ The server's event loop. @-}
runApp :: App a -> IO a
runApp (App s) = do
  (a, (_, vTable)) <- runStateT s initAppState
  {- BLOCKING HERE -}
  _ <- serve (Host localhost) connectPort $
    \(connectionSocket, remoteAddr) -> do
      -- debug log
      putStrLn $ "TCP connection established from " ++ show remoteAddr
      hFlush stdout -- Gramine prints only if stdout is flushed
      req <- readTCPSocket connectionSocket
      onEvent vTable req connectionSocket
  {- BLOCKING ENDS -}
  return a -- the a is irrelevant



onEvent :: [(CallID, Method)] -> ByteString -> Socket -> IO ()
onEvent mapping incoming socket = do
  let (identifier, args) = decode incoming :: (CallID, [ByteString])
      Just f = lookup identifier mapping
  result <- f args
  let res = handleVoidTy result -- the () type cannot be sent over wire
  sendLazy socket (B.append (msgSize res) res) -- See NOTE 1
  where
    msgSize r = encode $ B.length r
    handleVoidTy r = if (B.length r == 0) -- the () type has msg length 0
                     then encode '\0'
                     else r

-- NOTE 1
-- We do not use `createPayload` because as a first step it
-- encodes the message body to a ByteString. In case of the
-- server the `result` is already a ByteString. So it further
-- encodes the ByteString and gives a wrong result.
-- We can modify the `createPayload` function so that depending
-- on the value of some identifier term that we send, it decides
-- to encode or not encode the message body but then the type
-- will become an actual dependent type. (Keep it simple!)





----------------------LABELS and Sec----------------------------------

data L = L
data H = H

newtype Sec s a = MkSec a

instance Monad (Sec s) where
  return = pure

  MkSec a >>= k =
    MkSec $ let MkSec b = k a in b

instance Functor (Sec s) where
  fmap = liftM

instance Applicative (Sec s) where
  pure = sec
  MkSec ab <*> MkSec a = MkSec (ab a)


--used to protect value `a`
sec :: a -> Sec s a
sec = MkSec

-- look at a protected value given
-- that you can produce a security
-- level `s`
open :: Sec s a -> s -> a
open (MkSec a) s = s `seq` a

-- up :: forall a sl sh . Less sl sh => Sec sl a -> Sec sh a
-- up (MkSec x) = (less @sl @sh) `seq` sech
--   where
--     sech = (MkSec x)

-- -- only for trusted code
-- reveal :: Sec s a -> a
-- reveal (MkSec x) = x


declassify :: Sec H a -> Sec L a
declassify (MkSec x) = (MkSec x)

endorse :: Sec L a -> Sec H a
endorse (MkSec x) = (MkSec x)
