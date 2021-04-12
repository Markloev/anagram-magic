module Game exposing (..)


type GameState
    = NotStarted
    | Searching
    | Started Game


type alias Game =
    { phase : Phase
    , tileSelectionTurn : Bool
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
