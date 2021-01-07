module View exposing (view)

import Element exposing (Element, column, el, fill, height, padding, width)
import Element.Background as Background exposing (color)
import Html exposing (Html)
import Types
    exposing
        ( ColorTheme(..)
        , Model
        , Msg(..)
        )
import View.Style as Style
import Views.Home


view : Model -> Html Msg
view model =
    render <|
        column
            [ height <| Element.minimum model.screen.height <| fill
            , width fill
            , Background.color Style.backgroundTheme
            ]
            [ el
                [ padding 50
                , width fill
                , height fill
                ]
                <|
                Views.Home.view model
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