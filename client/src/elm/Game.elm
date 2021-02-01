module Game exposing (..)

import Time exposing (Posix)


type GameState
    = NotStarted String
    | Searching
    | Started SharedGame


type alias Game =
    { playerId : String
    , gameState : GameState
    , currentTime : Posix
    , startTime : Posix
    , elapsedTime : Int
    , selectedTiles : List Tile
    , availableTiles : List Tile
    , answerString : Maybe String
    , totalScore : Int
    , isSubmitted : Bool
    }


type alias SharedGame =
    { playerId : String
    , phase : Phase
    , round : Int
    , selectedTiles : List Tile
    , availableTiles : List Tile
    , answerString : Maybe String
    , totalScore : Int
    , isSubmitted : Bool
    }


type alias Tile =
    { letter : Char
    , value : Int
    , originalIndex : Int
    , hidden : Bool
    }


initGame : String -> Game
initGame playerId =
    { playerId = playerId
    , gameState = NotStarted ""
    , currentTime = Time.millisToPosix 0
    , startTime = Time.millisToPosix 0
    , elapsedTime = 0
    , selectedTiles = []
    , availableTiles = []
    , answerString = Nothing
    , totalScore = 0
    , isSubmitted = False
    }


initSharedGame : String -> Phase -> SharedGame
initSharedGame opponentId phase =
    { playerId = opponentId
    , phase = phase
    , round = 1
    , selectedTiles = []
    , availableTiles = []
    , answerString = Nothing
    , totalScore = 0
    , isSubmitted = False
    }


type Phase
    = Waiting
    | TileSelection
    | RegularRound
    | FinalRound
    | Completed
