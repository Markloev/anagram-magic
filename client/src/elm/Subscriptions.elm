module Subscriptions exposing (subscriptions)

import Constants exposing (timeInterval)
import Types exposing (Msg(..))
import Time
import Types exposing (Model, Msg(..))


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every timeInterval Tick