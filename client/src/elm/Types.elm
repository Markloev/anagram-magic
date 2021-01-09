module Types exposing (..)

import Time exposing (Posix)


type alias Model =
    { screen : Screen
    , errorMessage : Maybe String
    , selectedTiles : Maybe (List Tile)
    , availableTiles : Maybe (List Tile)
    , answerString : Maybe String
    , totalScore : Int
    , currentTime : Posix
    , startTime : Posix
    }


emptyModel : Model
emptyModel =
    { screen = { width = 0, height = 0 }
    , errorMessage = Nothing
    , selectedTiles = Nothing
    , availableTiles = Nothing
    , answerString = Nothing
    , totalScore = 0
    , currentTime = Time.millisToPosix 0
    , startTime = Time.millisToPosix 0
    }


type alias Tile =
    { letter : Char
    , points : Int
    }


type alias Screen =
    { width : Int
    , height : Int
    }


type ColorTheme
    = Light
    | Dark
