module Main exposing (main)

import Browser
import Msg exposing (Msg)
import Subscriptions exposing (subscriptions)
import Types exposing (Model, emptyModel)
import Update exposing (update)
import View exposing (view)


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : ( Model, Cmd Msg )
init =
    ( emptyModel, Cmd.none )
