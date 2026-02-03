{-# LANGUAGE DeriveGeneric #-}

module SnippetLs.Types
  ( Snippet (..),
    Message (..),
    Action (..),
  )
where

import Data.Aeson
  ( FromJSON (parseJSON),
    ToJSON (toJSON),
    Value (Null),
    object,
    withObject,
    (.:),
    (.:?),
  )
import Data.Text qualified as T
import GHC.Generics

-- Core types
data Snippet = Snippet
  { prefix :: T.Text,
    body :: [T.Text],
    description :: T.Text,
    language :: Maybe T.Text
  }
  deriving (Generic, Show)

instance FromJSON Snippet

instance ToJSON Snippet

-- Action for the server loop
data Action = Reply Message | Exit | None

-- LSP Message envelope
data Message = Message
  { jsonrpc :: T.Text,
    msgId :: Maybe Int,
    method :: Maybe T.Text,
    params :: Maybe Value,
    result :: Maybe Value
  }
  deriving (Generic, Show)

instance FromJSON Message where
  parseJSON = withObject "Message" $ \v ->
    Message
      <$> v .: "jsonrpc"
      <*> v .:? "id"
      <*> v .:? "method"
      <*> v .:? "params"
      <*> v .:? "result"

instance ToJSON Message where
  toJSON (Message rpc mid meth par res) =
    object $
      filter
        (notNull . snd)
        [ ("jsonrpc", toJSON rpc),
          ("id", toJSON mid),
          ("method", toJSON meth),
          ("params", toJSON par),
          ("result", toJSON res)
        ]
    where
      notNull Null = False
      notNull _ = True
