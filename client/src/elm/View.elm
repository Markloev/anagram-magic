module View exposing (view)

import Element exposing (Element, centerX, centerY, column, el, fill, height, padding, px, text, width)
import Element.Background as Background exposing (color)
import Html exposing (Html)
import Msg exposing (Msg(..))
import Types
    exposing
        ( ColorTheme(..)
        , Model
        )
import View.Style as Style


view : Model -> Html Msg
view model =
    let
        errorTxt =
            case model.errorMessage of
                Just txt ->
                    el [] <| text txt

                Nothing ->
                    Element.none
    in
    render <|
        column
            [ height <| Element.minimum model.screen.height <| fill
            , width fill
            ]
            [ el
                [ padding 50
                , width fill
                , height fill
                ]
              <|
                column [ centerX, centerY ]
                    [ errorTxt
                    , el [ width <| px 20, height <| px 20 ] <| text "txt"
                    ]
            ]


render : Element Msg -> Html Msg
render =
    Element.layoutWith
        { options =
            [ Element.focusStyle
                { borderColor = Nothing
                , backgroundColor = Nothing
                , shadow = Nothing
                }
            ]
        }
        [ height fill
        , width fill
        ]
