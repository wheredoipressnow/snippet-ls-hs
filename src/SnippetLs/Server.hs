module SnippetLs.Server
  ( runServer,
  )
where

import Data.Aeson (decode, encode)
import Data.ByteString.Char8 qualified as BS
import Data.ByteString.Lazy.Char8 qualified as BL
import SnippetLs.Completions (handleMessage, loadSnippets)
import SnippetLs.Types (Action (..), Snippet)
import System.Exit (exitSuccess)
import System.IO
  ( BufferMode (NoBuffering),
    hFlush,
    hIsEOF,
    hSetBinaryMode,
    hSetBuffering,
    stdin,
    stdout,
  )

-- Read Content-Length prefixed messages
readLSPMessage :: IO (Maybe BL.ByteString)
readLSPMessage = do
  eof <- hIsEOF stdin
  if eof
    then return Nothing
    else do
      headerLine <- BS.hGetLine stdin
      let contentLength = read $ drop 16 $ BS.unpack headerLine :: Int
      _ <- BS.hGetLine stdin
      Just <$> BL.hGet stdin contentLength

-- Write Content-Length prefixed messages
writeLSPMessage :: BL.ByteString -> IO ()
writeLSPMessage msg = do
  BS.hPutStr stdout $
    "Content-Length: " <> BS.pack (show $ BL.length msg) <> "\r\n\r\n"
  BL.hPut stdout msg
  hFlush stdout

-- Main server loop
runServer :: FilePath -> IO ()
runServer snippetsFolder = do
  snippets <- loadSnippets snippetsFolder
  hSetBuffering stdin NoBuffering
  hSetBuffering stdout NoBuffering
  hSetBinaryMode stdin True
  hSetBinaryMode stdout True
  loop snippets

loop :: [Snippet] -> IO ()
loop snippets = do
  mcontent <- readLSPMessage
  case mcontent of
    Nothing -> exitSuccess
    Just content -> case decode content of
      Just msg -> case handleMessage snippets msg of
        Reply response -> do
          writeLSPMessage $ encode response
          loop snippets
        Exit -> exitSuccess
        None -> loop snippets
      Nothing -> loop snippets
