module Types exposing (Model, initModel)

import Game exposing (GameState(..))
import WebSocket exposing (SocketStatus(..))


type alias Model =
    { gameState : GameState
    , opponentGameState : Maybe GameState
    , socketInfo : SocketStatus
    , playerId : String
    }


initModel : String -> Model
initModel playerId =
    { gameState = NotStarted ""
    , opponentGameState = Nothing
    , socketInfo = Unopened
    , playerId = playerId
    }
