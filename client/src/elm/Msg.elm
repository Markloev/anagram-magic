module Msg exposing (Msg(..))

import Game exposing (Game, SharedGame, Tile)
import Http
import Json.Decode as Decode
import Time
import WebSocket exposing (ConnectionInfo)


type Msg
    = DoNothing
    | Tick Time.Posix
    | KeyPressed Game (Maybe SharedGame) String
    | KeyCharPressed Game (Maybe SharedGame) Char
    | RemoveTileBackspace Game (Maybe SharedGame)
    | GetConsonant Game
    | GetVowel Game
    | GetRandom
    | ShuffleTiles Game
    | ReceiveRandomTiles Game (Maybe SharedGame) (Result Decode.Error (List Tile))
    | ReceiveShuffledTiles Game (Maybe SharedGame) (Result Decode.Error (List Tile))
    | SelectTile Game (Maybe SharedGame) Int Tile
    | RemoveTile Game (Maybe SharedGame) Int Int
    | Submit Game (Maybe SharedGame)
    | GetWordValidityResponse (Result Http.Error String)
    | GetRandomWordResponse (Result Http.Error String)
    | SocketConnect ConnectionInfo
    | SocketClosed Int (Maybe String)
    | ReceivedString String
    | Error String
    | StartSearch
