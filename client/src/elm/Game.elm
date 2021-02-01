module Game exposing (..)

import Time exposing (Posix)


type GameState
    = NotStarted String
    | Searching
    | Started Game (Maybe SharedGame)


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
    , isSubmitted = False
    }


initSharedGame : String -> SharedGame
initSharedGame opponentId =
    { playerId = opponentId
    , phase = TileSelection
    , round = 1
    , selectedTiles = []
    , availableTiles = []
    , answerString = Nothing
    , totalScore = 0
    , isSubmitted = False
    }


type Phase
    = TileSelection
    | RegularRound
    | FinalRound
    | Completed
