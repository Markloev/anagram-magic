module Msg exposing (Msg(..))

import Game exposing (Game, Tile)
import Json.Decode as Decode
import Time
import WebSocket exposing (ConnectionInfo)


type Msg
    = StartSearch
    | StopSearch
    | Tick Game Time.Posix
    | KeyPressed String
    | KeyCharPressed Game Char
    | GetConsonant Game
    | GetVowel Game
    | GetRandom
    | ReceiveRandomTiles Game (Result Decode.Error (List Tile))
    | ShuffleTiles Game
    | ReceiveShuffledTiles Game (Result Decode.Error (List Tile))
    | RemoveTileBackspace Game
    | SelectTile Game Int Tile
    | RemoveTile Game Int Int
    | Submit Game
    | NextRound Game
    | Continue Game
    | EndGame
    | SocketConnect ConnectionInfo
    | SocketClosed Int (Maybe String)
    | ReceivedString String
    | Error String
