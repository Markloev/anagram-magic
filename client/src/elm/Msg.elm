module Msg exposing (Msg(..))

import Game exposing (SharedGame, Tile)
import Http
import Json.Decode as Decode
import Time
import WebSocket exposing (ConnectionInfo)


type Msg
    = DoNothing
    | Tick Time.Posix
    | KeyPressed SharedGame String
    | KeyCharPressed Char
    | RemoveTileBackspace
    | GetConsonant
    | GetVowel
    | GetRandom
    | ShuffleTiles
    | ReceiveRandomTiles SharedGame (Result Decode.Error (List Tile))
    | ReceiveShuffledTiles (Result Decode.Error (List Tile))
    | SelectTile Int Tile
    | RemoveTile Int Int
    | Submit SharedGame
    | GetWordValidityResponse (Result Http.Error String)
    | GetRandomWordResponse (Result Http.Error String)
    | SocketConnect ConnectionInfo
    | SocketClosed Int (Maybe String)
    | ReceivedString String
    | Error String
    | StartSearch
