module Views.Header exposing (view)

import Element exposing (Element, centerY, el, fill, height, padding, px, row, spacing, text, width)
import Element.Border exposing (shadow)
import Element.Font as Font
import Element.Input as Input
import Material.Icons.Types exposing (Coloring(..))
import Types
    exposing
        ( ColorTheme(..)
        , Msg(..)
        , Route(..)
        , View(..)
        )
import View.Style as Style


view : Element Msg
view =
    el [ height <| px 40, shadow { offset = ( 0, 0 ), size = 0, blur = 7, color = Style.borderTheme }, width fill, padding 5, spacing 10 ] <|
        row [ centerY, width fill, spacing 10 ] <|
            [ row [ spacing 10 ]
                [ Input.button [ Font.bold ]
                    { onPress = Just <| UrlChange RouteHome, label = text "Home" }
                ]
            , row [ spacing 10 ]
                [ Input.button [ Font.bold ]
                    { onPress = Just <| UrlChange RouteAbout, label = text "About" }
                ]
            ]
