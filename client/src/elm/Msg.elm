module Msg exposing (Msg(..))

import Array exposing (Array)
import Browser.Dom as Dom
import Game exposing (Game, GameState, Tile)
import Json.Decode as Decode
import Time


type Msg
    = DoNothing
    | FocusOn String
    | FocusResult (Result Dom.Error ())
    | Tick Time.Posix
    | StartGame
    | GetConsonant Game
    | GetVowel Game
    | GetRandom
    | ShuffleTiles Game
    | ReceiveRandomTiles GameState (Result Decode.Error (Array Tile))
    | ReceiveShuffledTiles GameState (Result Decode.Error (Array Tile))
    | SelectTile Game Int Tile
    | RemoveTile Game Int Int Tile
