module Game exposing (..)

import Time exposing (Posix)


type GameState
    = NotStarted
    | Started Game


type alias Game =
    { currentTime : Posix
    , startTime : Posix
    , elapsedTime : Int
    , phase : Phase
    , round : Int
    , selectedTiles : List Tile
    , availableTiles : List Tile
    , answerString : Maybe String
    , totalScore : Int
    }


type alias Tile =
    { letter : Char
    , value : Int
    , originalIndex : Int
    , hidden : Bool
    }


initGame : Game
initGame =
    { currentTime = Time.millisToPosix 0
    , startTime = Time.millisToPosix 0
    , elapsedTime = 0
    , phase = TileSelection
    , round = 1
    , selectedTiles = []
    , availableTiles = []
    , answerString = Nothing
    , totalScore = 0
    }


type Phase
    = TileSelection
    | RegularRound
    | FinalRound


isRunning : GameState -> Bool
isRunning gameState =
    gameState /= NotStarted
