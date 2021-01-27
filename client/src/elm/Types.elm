module Types exposing (Model, initModel)

import Game exposing (GameState(..))


type alias Model =
    { gameState : GameState
    , serverMessage : String
    }


initModel : Model
initModel =
    { gameState = NotStarted
    , serverMessage = ""
    }
