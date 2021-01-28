module Main exposing (main)

import Browser
import Http
import Msg exposing (Msg(..))
import Subscriptions exposing (subscriptions)
import Types exposing (Model, initModel)
import Update exposing (update)
import View exposing (view)


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , view =
            \m ->
                { title = "Anagram Magic"
                , body = [ view m ]
                }
        , subscriptions = subscriptions
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( initModel
    , Http.get
        { url = "http://localhost:3000"
        , expect = Http.expectString GotTicket
        }
    )
