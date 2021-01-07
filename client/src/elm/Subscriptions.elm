module Subscriptions exposing (subscriptions)

import Ports
import Routing
import Types exposing (Model, Msg(..))


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.onUrlChange (Routing.router >> UrlChange)
