module Game exposing (..)

import Time exposing (Posix)


type GameState
    = NotStarted String
    | Searching
    | Started SharedGame


type alias Game =
    { playerId : String
    , gameState : GameState
    , tileSelectionTurn : Bool
    , currentTime : Posix
    , startTime : Posix
    , elapsedTime : Int
    , selectedTiles : List Tile
    , availableTiles : List Tile
    , answerString : Maybe String
    , totalScore : Int
    , turnSubmitted : Bool
    , validWord : Bool
    }


type alias SharedGame =
    { playerId : String
    , phase : Phase
    , selectedTiles : List Tile
    , availableTiles : List Tile
    , answerString : Maybe String
    , totalScore : Int
    , turnSubmitted : Bool
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
    , gameState = NotStarted ""
    , tileSelectionTurn = False
    , currentTime = Time.millisToPosix 0
    , startTime = Time.millisToPosix 0
    , elapsedTime = 0
    , selectedTiles = []
    , availableTiles = []
    , answerString = Nothing
    , totalScore = 0
    , turnSubmitted = False
    , validWord = False
    }


initSharedGame : String -> Phase -> SharedGame
initSharedGame opponentId phase =
    { playerId = opponentId
    , phase = phase
    , selectedTiles = []
    , availableTiles = []
    , answerString = Nothing
    , totalScore = 0
    , turnSubmitted = False
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
