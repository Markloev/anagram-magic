module View exposing (view)

import Element exposing (Element, column, el, fill, height, padding, width, px, text, centerX, centerY)
import Element.Background as Background exposing (color)
import Html exposing (Html)
import Types
    exposing
        ( ColorTheme(..)
        , Model
        , Msg(..)
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
                    , el [ width <| px 20, height <| px 20 ] <| model.selectedTiles.letter
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