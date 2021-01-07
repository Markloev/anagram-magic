module View exposing (view)

import Element exposing (Element, column, el, fill, height, padding, width)
import Element.Background as Background exposing (color)
import Html exposing (Html)
import Types
    exposing
        ( ColorTheme(..)
        , Model
        , Msg(..)
        , View(..)
        )
import View.Style as Style
import Views.Header as Header
import Views.Home
import Views.About


view : Model -> Html Msg
view model =
    let
        body =
            case model.view of
                ViewHome ->
                    Views.Home.view model

                ViewAbout ->
                    Views.About.view model
    in
    render <|
        column
            [ height <| Element.minimum model.screen.height <| fill
            , width fill
            , Background.color Style.backgroundTheme
            ]
            [ Header.view
            , el
                [ padding 50
                , width fill
                , height fill
                ]
                <|
                body
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