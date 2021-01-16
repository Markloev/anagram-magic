module Subscriptions exposing (subscriptions)

import Constants exposing (timeInterval)
import Types exposing (Msg(..), GameState(..))
import Time
import Types exposing (Model, Msg(..))


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.gameState of
        Stopped ->
            Sub.none
        
        Started _ ->
            Time.every timeInterval Tick