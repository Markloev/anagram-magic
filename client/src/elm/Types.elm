module Types exposing (Model, initModel)

import Game exposing (GameState(..))
import WebSocket exposing (SocketStatus(..))


type alias Model =
    { gameState : GameState
    , serverMessage : String
    , socketMessage : String
    , socketInfo : SocketStatus
    , testString : String
    , testReceivedString : List String
    }


initModel : Model
initModel =
    { gameState = NotStarted ""
    , serverMessage = ""
    , socketMessage = ""
    , socketInfo = Unopened
    , testString = ""
    , testReceivedString = []
    }
