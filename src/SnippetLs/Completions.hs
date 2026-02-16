module SnippetLs.Completions
  ( handleMessage,
    loadSnippets,
  )
where

import Data.Aeson
  ( ToJSON (toJSON),
    Value (Bool, Null, Number),
    eitherDecodeFileStrict,
    object,
  )
import Data.Text qualified as T
import SnippetLs.Types
  ( Action (..),
    Message (Message, method, msgId),
    Snippet,
    body,
    description,
    prefix,
  )
import System.Directory (listDirectory)
import System.FilePath (takeExtension, (</>))
import System.IO (hPutStrLn, stderr)

loadSnippets :: FilePath -> IO [Snippet]
loadSnippets dir = do
  files <- listDirectory dir
  let jsonFiles = filter (\f -> takeExtension f == ".json") files
  result <- mapM loadFile jsonFiles
  return $ concat [s | Right s <- result]
  where
    loadFile :: FilePath -> IO (Either String [Snippet])
    loadFile file = do
      res <- eitherDecodeFileStrict (dir </> file)
      case res of
        Left err -> do
          hPutStrLn stderr $ "Warning: failed to parse " <> file <> ": " <> err
          return (Right [])
        Right ss -> return (Right ss)

-- Convert snippet to completion item
toCompletionItem :: Snippet -> Value
toCompletionItem s =
  object
    [ ("label", toJSON $ prefix s),
      ("kind", Number 15), -- Snippet kind
      ("detail", toJSON $ description s),
      ("insertText", toJSON $ T.intercalate "\n" $ body s),
      ("insertTextFormat", Number 2) -- Snippet format
    ]

-- Handle requests
handleMessage :: [Snippet] -> Message -> Action
handleMessage snippets msg = case method msg of
  Just "initialize" ->
    Reply $
      Message
        "2.0"
        (msgId msg)
        Nothing
        Nothing
        ( Just $
            object
              [ ( "capabilities",
                  object
                    [ ("textDocumentSync", Number 1),
                      ("completionProvider", object [("resolveProvider", Bool False)])
                    ]
                )
              ]
        )
  Just "shutdown" ->
    Reply $
      Message
        "2.0"
        (msgId msg)
        Nothing
        Nothing
        (Just Null)
  Just "exit" -> Exit
  Just "textDocument/completion" ->
    Reply $
      Message
        "2.0"
        (msgId msg)
        Nothing
        Nothing
        (Just $ toJSON $ map toCompletionItem snippets)
  _ -> None
