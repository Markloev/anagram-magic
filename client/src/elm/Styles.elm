module Styles exposing (..)

import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, classList, disabled, style)
import Html.Events exposing (onClick)
import Msg exposing (Msg(..))


styledButton : Msg -> String -> Maybe String -> Html Msg
styledButton cmd label classes =
    button
        [ onClick cmd
        , "p-2 my-2 bg-blue-400 text-white rounded-md focus:outline-none focus:ring-2 ring-blue-200 "
            ++ Maybe.withDefault "" classes
            |> class
        ]
        [ text label ]


tileClasses : String
tileClasses =
    "w-12 h-12"
