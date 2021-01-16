module Types exposing (Model, Msg(..), Game, GameState(..), Phase(..), emptyModel, initGame)

import Browser.Dom as Dom
import Http
import Time exposing (Posix)


type alias Model =
    { gameState : GameState
    }


emptyModel : Model
emptyModel =
    { gameState = Stopped
    }


type alias Tile =
    { letter : Char
    , points : Int
    }


type Msg
    = DoNothing
    | FocusOn String
    | FocusResult (Result Dom.Error ())
    | GetResponse (Result Http.Error String)
    | Tick Time.Posix
    | StartGame


type GameState
    = Stopped
    | Started Game


type alias Game =
    { currentTime : Posix
    , startTime : Posix
    , phase : Phase
    , selectedTiles : Maybe (List Tile)
    , availableTiles : Maybe (List Tile)
    , answerString : Maybe String
    , totalScore : Int
    }

initGame : Game
initGame =
    { currentTime = Time.millisToPosix 0
    , startTime = Time.millisToPosix 0
    , phase = TileSelection
    , selectedTiles = Nothing
    , availableTiles = Nothing
    , answerString = Nothing
    , totalScore = 0
    }

type Phase
    = TileSelection
    | RegularRound
    | FinalRound