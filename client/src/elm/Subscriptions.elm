module Subscriptions exposing (subscriptions)

import Constants exposing (timeInterval)
import Msg exposing (Msg(..))
import Time
import Types exposing (Model)


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every timeInterval Tick
