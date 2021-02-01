module Msg exposing (Msg(..))

import Game exposing (Game, SharedGame, Tile)
import Http
import Json.Decode as Decode
import Time
import WebSocket exposing (ConnectionInfo)


type Msg
    = DoNothing
    | Tick Time.Posix
    | KeyPressed Game SharedGame String
    | KeyCharPressed Game SharedGame Char
    | RemoveTileBackspace Game SharedGame
    | GetConsonant Game
    | GetVowel Game
    | GetRandom
    | ShuffleTiles Game
    | ReceiveRandomTiles Game SharedGame (Result Decode.Error (List Tile))
    | ReceiveShuffledTiles Game SharedGame (Result Decode.Error (List Tile))
    | SelectTile Game SharedGame Int Tile
    | RemoveTile Game SharedGame Int Int
    | Submit Game SharedGame
    | GetWordValidityResponse (Result Http.Error String)
    | GetRandomWordResponse (Result Http.Error String)
    | SocketConnect ConnectionInfo
    | SocketClosed Int (Maybe String)
    | ReceivedString String
    | Error String
    | StartSearch
