module Msg exposing (Msg(..))

import Game exposing (SharedGame, Tile)
import Json.Decode as Decode
import Time
import WebSocket exposing (ConnectionInfo)


type Msg
    = StartSearch
    | StopSearch
    | Tick Time.Posix
    | KeyPressed SharedGame String
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
    | Submit
    | NextRound
    | SocketConnect ConnectionInfo
    | SocketClosed Int (Maybe String)
    | ReceivedString String
    | Error String
