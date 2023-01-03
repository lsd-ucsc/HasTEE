{-# LANGUAGE GeneralizedNewtypeDeriving, StaticPointers #-}
module App (module App) where

import Control.Monad.IO.Class
import Control.Monad.Trans.State.Strict
import Data.ByteString.Lazy(ByteString, append, length, fromStrict)
import Data.Binary(Binary, encode, decode)
import Data.Maybe(fromMaybe)
import Network.Simple.TCP

{-@ The EnclaveIFC API for programmers

-- use the below 2 function to describe your server API
liftServerIO :: IO a -> App (Server a)
remote :: Remotable a => a -> App (Remote a)

-- use the below function to introduce the Client monad
runClient :: Client () -> App Done


-- use the 2 functions below to talk to the server
-- inside the Client monad
onServer :: Remote (Server a) -> Client a
(<.>) :: Binary a => Remote (a -> b) -> a -> Remote b

-- call this from `main` to run the App monad
runApp :: App a -> IO a


@-}


type CallID = Int
type Method = [ByteString] -> IO ByteString
type AppState = (CallID, [(CallID, Method)])
newtype App a = App (StateT AppState IO a)
  deriving (Functor, Applicative, Monad, MonadIO)

data Done = Done

initAppState :: AppState
initAppState = (0,[])

-- Client-server communication utils follow

localhost :: String
localhost = "127.0.0.1"

connectPort :: String
connectPort = "8000"

{-@ `createPayload` creates the  binary request to send over TCP.

     The payload comprise of:
     8 bytes message length followed by n bytes message body
     where n :: Int64 (from the length function in `bytestring`)

@-}
createPayload :: Binary a => a -> ByteString
createPayload msg = append bytstr msgBody
  where
    msgBody = encode msg
    msgSize = Data.ByteString.Lazy.length msgBody
    bytstr  = encode msgSize

readTCPSocket :: (MonadIO m) => Socket -> m ByteString
readTCPSocket socket = do
  -- first 8 bytes (Int64) encodes the msg size
  mSize <- recv socket 8
  let mSize_ = fromMaybe err mSize
  -- read the actual message body now
  msgBody <- recv socket (decode $ fromStrict mSize_)
  return $ fromStrict $ fromMaybe err msgBody
  where
    err = error "Error parsing request"