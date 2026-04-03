module SnippetLs.Server
  ( runServer,
  )
where

import Data.Aeson (decode, encode)
import Data.ByteString.Char8 qualified as BS
import Data.ByteString.Lazy.Char8 qualified as BL
import Data.List (stripPrefix)
import SnippetLs.Completions (handleMessage, loadSnippets)
import SnippetLs.Types (Action (..), Snippet)
import System.Exit (exitSuccess)
import System.IO
  ( BufferMode (NoBuffering),
    hFlush,
    hIsEOF,
    hPutStrLn,
    hSetBinaryMode,
    hSetBuffering,
    stderr,
    stdin,
    stdout,
  )
import Text.Read (readMaybe)

data ReadResult = EOF | Msg BL.ByteString

-- Read Content-Length prefixed messages, handling any number of headers
readLSPMessage :: IO ReadResult
readLSPMessage = do
  eof <- hIsEOF stdin
  if eof
    then return EOF
    else readHeaders Nothing
  where
    readHeaders mlen = do
      line <- BS.hGetLine stdin
      let stripped = filter (/= '\r') $ BS.unpack line
      if null stripped
        then case mlen of
          Nothing -> do
            hPutStrLn stderr "Warning: no Content-Length header found, skipping message"
            return EOF
          Just n -> Msg <$> BL.hGet stdin n
        else case stripPrefix "Content-Length: " stripped of
          Just rest -> case readMaybe rest of
            Just n -> readHeaders (Just n)
            Nothing -> do
              hPutStrLn stderr $ "Warning: invalid Content-Length value: " <> rest
              readHeaders mlen
          Nothing -> readHeaders mlen -- ignore unknown headers

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
  hPutStrLn stderr "snippet-ls 0.1.0.0 starting"
  snippets <- loadSnippets snippetsFolder
  hPutStrLn stderr $ "snippet-ls loaded " <> show (length snippets) <> " snippet(s)"
  hSetBuffering stdin NoBuffering
  hSetBuffering stdout NoBuffering
  hSetBinaryMode stdin True
  hSetBinaryMode stdout True
  loop snippets

loop :: [Snippet] -> IO ()
loop snippets = do
  result <- readLSPMessage
  case result of
    EOF -> exitSuccess
    Msg content -> do
      case decode content of
        Just msg -> case handleMessage snippets msg of
          Reply response -> do
            writeLSPMessage $ encode response
            loop snippets
          Exit -> exitSuccess
          None -> loop snippets
        Nothing -> do
          hPutStrLn stderr $ "Warning: failed to decode message: " <> BL.unpack content
          loop snippets
