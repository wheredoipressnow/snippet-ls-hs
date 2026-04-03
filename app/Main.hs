module Main (main) where

import Data.Maybe (listToMaybe)
import SnippetLs.Server (runServer)
import System.Environment (getArgs)
import System.IO (hPutStrLn, stderr)

getSnippetPath :: IO (Maybe FilePath)
getSnippetPath = listToMaybe <$> getArgs

main :: IO ()
main = do
  snippetsPath <- getSnippetPath
  maybe (hPutStrLn stderr "Error: snippets path must be specified") runServer snippetsPath
