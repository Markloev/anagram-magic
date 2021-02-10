module Game exposing (..)

import Time exposing (Posix)


type GameState
    = NotStarted
    | Searching
    | Started SharedGame


type alias Game =
    { playerId : String
    , gameState : GameState
    , tileSelectionTurn : Bool
    , currentTime : Posix
    , startedTime : Posix
    , timeInterval : Int
    , elapsedTime : Int
    , selectedTiles : List Tile
    , availableTiles : List Tile
    , totalScore : Int
    , waitingForUser : Bool
    , validWord : Bool
    , errorOccurred : Bool
    }


type alias SharedGame =
    { playerId : String
    , phase : Phase
    , selectedTiles : List Tile
    , totalScore : Int
    , waitingForUser : Bool
    , validWord : Bool
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
    , gameState = NotStarted
    , tileSelectionTurn = False
    , currentTime = Time.millisToPosix 0
    , startedTime = Time.millisToPosix 0
    , timeInterval = 0
    , elapsedTime = 0
    , selectedTiles = []
    , availableTiles = []
    , totalScore = 0
    , waitingForUser = False
    , validWord = False
    , errorOccurred = False
    }


initSharedGame : String -> Phase -> SharedGame
initSharedGame opponentId phase =
    { playerId = opponentId
    , phase = phase
    , selectedTiles = []
    , totalScore = 0
    , waitingForUser = False
    , validWord = False
    }


type Phase
    = Waiting SpecificRound
    | TileSelection SpecificRound
    | Round SpecificRound
    | CompletedRound SpecificRound
    | CompletedGame


type SpecificRound
    = FirstRound
    | SecondRound
    | ThirdRound
    | FourthRound
    | FinalRound
