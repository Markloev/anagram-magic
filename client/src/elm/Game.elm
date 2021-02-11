module Game exposing (..)

import Time exposing (Posix)


type GameState
    = NotStarted
    | Searching
    | Started Game


type alias Game =
    { phase : Phase
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
    , shared : Shared
    }


type alias Shared =
    { playerId : String
    , selectedTiles : List Tile
    , totalScore : Int
    , waitingForUser : Bool
    , validWord : Bool
    }


initGame : Bool -> String -> Phase -> Game
initGame tileSelectionTurn opponentId phase =
    { phase = phase
    , tileSelectionTurn = tileSelectionTurn
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
    , shared = initShared opponentId
    }


initShared : String -> Shared
initShared opponentId =
    { playerId = opponentId
    , selectedTiles = []
    , totalScore = 0
    , waitingForUser = False
    , validWord = False
    }


type alias Tile =
    { letter : Char
    , value : Int
    , originalIndex : Int
    , hidden : Bool
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
