module Types exposing (Model, initModel)

import Game exposing (GameState(..))
import WebSocket exposing (SocketStatus(..))


type alias Model =
    { gameState : GameState
    , opponentGameState : Maybe GameState
    , serverMessage : String
    , socketMessage : String
    , socketInfo : SocketStatus
    , testString : String
    , testReceivedString : List String
    , playerId : String
    , opponentId : Maybe String
    }


initModel : String -> Model
initModel playerId =
    { gameState = NotStarted ""
    , opponentGameState = Nothing
    , serverMessage = ""
    , socketMessage = ""
    , socketInfo = Unopened
    , testString = ""
    , testReceivedString = []
    , playerId = playerId
    , opponentId = Nothing
    }
