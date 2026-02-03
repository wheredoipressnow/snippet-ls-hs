module SnippetLs.Completions
  ( snippets,
    toCompletionItem,
    handleMessage,
  )
where

import Data.Aeson
  ( ToJSON (toJSON),
    Value (Bool, Null, Number),
    object,
  )
import Data.Text qualified as T
import SnippetLs.Types

-- Hardcoded snippets
snippets :: [Snippet]
snippets =
  [ Snippet
      "exl"
      [ "IO.inspect(\"---------------------------------------\")",
        "IO.inspect(${1}, label: \"${2}\")",
        "IO.inspect(\"---------------------------------------\")"
      ]
      "Insert IO.inspect surrounded by decorative border"
      (Just "elixir"),
    Snippet
      "ii"
      ["IO.inspect($1, label: \"$2\")"]
      "Insert IO.inspect with label"
      (Just "elixir"),
    Snippet
      "iib"
      ["IO.inspect(binding(), label: \"$1\")"]
      "Insert IO.inspect with current binding"
      (Just "elixir"),
    Snippet
      "test"
      [ "test \"$1\" do",
        "  $2",
        "end"
      ]
      "Create a new ExUnit test"
      (Just "elixir"),
    Snippet
      "desc"
      [ "describe \"$1\" do",
        "  $2",
        "end"
      ]
      "Create a new ExUnit describe block"
      (Just "elixir"),
    Snippet
      "setup"
      [ "setup do",
        "  $1",
        "  :ok",
        "end"
      ]
      "Create a new ExUnit setup block"
      (Just "elixir")
  ]

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
handleMessage :: Message -> Action
handleMessage msg = case method msg of
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
