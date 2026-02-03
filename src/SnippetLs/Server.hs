module SnippetLs.Server
  ( runServer,
  )
where

import Data.Aeson (decode, encode)
import Data.ByteString.Char8 qualified as BS
import Data.ByteString.Lazy.Char8 qualified as BL
import SnippetLs.Completions (handleMessage)
import SnippetLs.Types (Action (..))
import System.Exit (exitSuccess)
import System.IO
  ( BufferMode (NoBuffering),
    hFlush,
    hSetBinaryMode,
    hSetBuffering,
    stdin,
    stdout,
  )

-- Read Content-Length prefixed messages
readLSPMessage :: IO BL.ByteString
readLSPMessage = do
  headerLine <- BS.hGetLine stdin
  let contentLength = read $ drop 16 $ BS.unpack headerLine :: Int
  _ <- BS.hGetLine stdin
  BL.hGet stdin contentLength

-- Write Content-Length prefixed messages
writeLSPMessage :: BL.ByteString -> IO ()
writeLSPMessage msg = do
  BS.hPutStr stdout $
    "Content-Length: " <> BS.pack (show $ BL.length msg) <> "\r\n\r\n"
  BL.hPut stdout msg
  hFlush stdout

-- Main server loop
runServer :: IO ()
runServer = do
  hSetBuffering stdin NoBuffering
  hSetBuffering stdout NoBuffering
  hSetBinaryMode stdin True
  hSetBinaryMode stdout True
  loop

loop :: IO ()
loop = do
  content <- readLSPMessage
  case decode content of
    Just msg -> case handleMessage msg of
      Reply response -> do
        writeLSPMessage $ encode response
        loop
      Exit -> exitSuccess
      None -> loop
    Nothing -> loop
