module Types exposing (Model, emptyModel)

import Browser.Dom as Dom
import Game exposing (GameState(..))
import Time exposing (Posix)


type alias Model =
    { gameState : GameState
    }


emptyModel : Model
emptyModel =
    { gameState = NotStarted
    }