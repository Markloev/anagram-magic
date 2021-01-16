module Msg exposing (..)

import Browser.Dom as Dom
import Time


type Msg
    = DoNothing
    | FocusOn String
    | FocusResult (Result Dom.Error ())
    | Tick Time.Posix
    | StartGame