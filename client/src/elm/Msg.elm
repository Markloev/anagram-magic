module Msg exposing (Msg(..))

import Browser.Dom as Dom
import Game exposing (Game, GameState, Tile)
import Json.Decode as Decode
import Time


type Msg
    = DoNothing
    | FocusOn String
    | FocusResult (Result Dom.Error ())
    | Tick Time.Posix
    | KeyPressed GameState String
    | KeyCharPressed Game Char
    | RemoveTileBackspace Game
    | StartGame
    | GetConsonant Game
    | GetVowel Game
    | GetRandom
    | ShuffleTiles Game
    | ReceiveRandomTiles GameState (Result Decode.Error (List Tile))
    | ReceiveShuffledTiles GameState (Result Decode.Error (List Tile))
    | SelectTile Game Int Tile
    | RemoveTile Game Int Int
    | Submit Game
