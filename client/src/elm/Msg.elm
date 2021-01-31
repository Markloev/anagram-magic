module Msg exposing (Msg(..))

import Game exposing (Game, Tile)
import Http
import Json.Decode as Decode
import Time
import WebSocket exposing (ConnectionInfo)


type Msg
    = DoNothing
    | Tick Time.Posix
    | KeyPressed Game String
    | KeyCharPressed Game Char
    | RemoveTileBackspace Game
    | StartGame
    | GetConsonant Game
    | GetVowel Game
    | GetRandom
    | ShuffleTiles Game
    | ReceiveRandomTiles Game (Result Decode.Error (List Tile))
    | ReceiveShuffledTiles Game (Result Decode.Error (List Tile))
    | SelectTile Game Int Tile
    | RemoveTile Game Int Int
    | Submit Game
    | GetWordValidityResponse (Result Http.Error String)
    | GetRandomWordResponse (Result Http.Error String)
    | ReceiveSocketMessage String
    | SocketConnect ConnectionInfo
    | SocketClosed Int (Maybe String)
    | ReceivedString String
    | Error String
    | ChangeString String
    | SendMessage
    | StartSearch
