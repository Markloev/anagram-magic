module Msg exposing (Msg(..))

import Game exposing (Phase, SharedGame, Tile)
import Json.Decode as Decode
import Time
import WebSocket exposing (ConnectionInfo)


type Msg
    = NoOp
    | StartSearch
    | StopSearch
    | Tick Time.Posix
    | KeyPressed String
    | KeyCharPressed Char
    | GetConsonant
    | GetVowel
    | GetRandom
    | ReceiveRandomTiles SharedGame (Result Decode.Error (List Tile))
    | ShuffleTiles
    | ReceiveShuffledTiles (Result Decode.Error (List Tile))
    | RemoveTileBackspace
    | SelectTile Int Tile
    | RemoveTile Int Int
    | Submit Phase
    | NextRound Phase
    | Continue
    | EndGame
    | SocketConnect ConnectionInfo
    | SocketClosed Int (Maybe String)
    | ReceivedString String
    | Error String
