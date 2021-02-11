module Types exposing (Model, initModel)

import Game exposing (GameState(..))
import WebSocket exposing (SocketStatus(..))


type alias Model =
    { gameState : GameState
    , playerId : String
    , socketInfo : SocketStatus
    }


initModel : String -> Model
initModel playerId =
    { gameState = NotStarted
    , playerId = playerId
    , socketInfo = Unopened
    }
