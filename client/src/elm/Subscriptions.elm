module Subscriptions exposing (subscriptions)

import Constants exposing (timeInterval)
import Game exposing (GameState(..), isRunning)
import Msg exposing (Msg(..))
import Prelude exposing (iff)
import Time
import Types exposing (Model)


subscriptions : Model -> Sub Msg
subscriptions { gameState } =
    iff (isRunning gameState) tick Sub.none


tick =
    Time.every timeInterval Tick
