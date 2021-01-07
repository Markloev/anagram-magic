module Subscriptions exposing (subscriptions)

import Ports
import Types exposing (Model, Msg(..))


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
