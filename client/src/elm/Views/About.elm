module Views.About exposing (view)

import Element exposing (Element, centerX, centerY, column, el, text)
import Types
    exposing
        ( Model
        , Msg(..)
        )


view : Model -> Element Msg
view model =
    let
        errorTxt =
            case model.errorMessage of
                Just txt ->
                    el [] <| text txt

                Nothing ->
                    Element.none
    in
    column [ centerX, centerY ]
        [ errorTxt
        , el [] <| text "About"
        ]