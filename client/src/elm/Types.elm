module Types exposing (Model, initModel)

import Game exposing (Game, GameState(..), SharedGame, initGame)
import WebSocket exposing (SocketStatus(..))


type alias Model =
    { game : Game
    , socketInfo : SocketStatus
    }


initModel : String -> Model
initModel playerId =
    { game = initGame playerId
    , socketInfo = Unopened
    }
