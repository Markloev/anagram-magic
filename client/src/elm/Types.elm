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
    , playerId : String
    , player2Id : Maybe String
    }


initModel : String -> Model
initModel playerId =
    { gameState = NotStarted ""
    , serverMessage = ""
    , socketMessage = ""
    , socketInfo = Unopened
    , testString = ""
    , testReceivedString = []
    , playerId = playerId
    , player2Id = Nothing
    }
