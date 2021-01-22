module Msg exposing (..)

import Browser.Dom as Dom
import Game exposing (Game)
import Time


type Msg
    = DoNothing
    | FocusOn String
    | FocusResult (Result Dom.Error ())
    | Tick Time.Posix
    | StartGame
    | GetConsonant Game 
    | GetVowel Game
    | GetRandom Game
    | GenerateRandomLetter Game (Int, Int)
    | GenerateRandomConsonant Game Int
    | GenerateRandomVowel Game Int