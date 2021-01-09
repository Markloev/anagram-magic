module Msg exposing (..)

import Browser.Dom as Dom
import Http
import Time
import Types exposing (Screen)


type Msg
    = DoNothing
    | Resize Screen
    | FocusOn String
    | FocusResult (Result Dom.Error ())
    | SetViewportCb
    | GetResponse (Result Http.Error String)
    | Tick Time.Posix
    | Start
    | Stop
