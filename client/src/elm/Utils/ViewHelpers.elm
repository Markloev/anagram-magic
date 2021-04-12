module Utils.ViewHelpers exposing (..)

import Constants exposing (consonants, maxConsonantOrVowel, vowels)
import Game exposing (Phase(..), SpecificRound(..), Tile)
import Html exposing (Attribute, Html, button, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Msg exposing (Msg(..))
import WebSocket.WebSocket exposing (SocketStatus(..))


repeatHtml : Int -> Html Msg -> List (Html Msg)
repeatHtml n html =
    if n <= 0 then
        []

    else
        List.append (repeatHtml (n - 1) html) [ html ]


hasMaxConsonants : List Tile -> Bool
hasMaxConsonants tiles =
    List.length
        (List.filter
            (\isConsonant -> isConsonant == True)
            (List.map
                (\tile ->
                    List.member tile.letter consonants
                )
                tiles
            )
        )
        >= maxConsonantOrVowel


hasMaxVowels : List Tile -> Bool
hasMaxVowels tiles =
    List.length
        (List.filter
            (\isVowel -> isVowel == True)
            (List.map
                (\tile ->
                    List.member tile.letter vowels
                )
                tiles
            )
        )
        >= maxConsonantOrVowel


unshuffleFinalWord : List Tile -> List Tile
unshuffleFinalWord tiles =
    List.sortBy (\tile -> tile.originalIndex) tiles


styledButton : Msg -> String -> Maybe String -> Html Msg
styledButton cmd label classes =
    button
        [ onClick cmd
        , "p-2 my-2 h-12 bg-blue-400 text-white rounded-md focus:outline-none focus:ring-2 ring-blue-200 "
            ++ Maybe.withDefault "" classes
            |> class
        ]
        [ text label ]


styledDisabledButton : String -> Maybe String -> Html Msg
styledDisabledButton label classes =
    button
        [ "flex items-center justify-center p-2 my-2 h-12 bg-gray-300 text-white rounded-md "
            ++ Maybe.withDefault "" classes
            |> class
        , style "cursor" "default"
        ]
        [ text label ]


styledTile : Tile -> Attribute Msg -> Maybe String -> Html Msg
styledTile tile clickAttr classes =
    div
        [ style "cursor" "pointer"
        , "p-2 my-2 w-12 h-12 bg-blue-400 text-white rounded-md focus:outline-none focus:ring-2 ring-blue-200 "
            ++ Maybe.withDefault "" classes
            |> class
        , clickAttr
        ]
        [ div [ class "text-center" ]
            [ text <| String.fromChar tile.letter ]
        , div [ class "text-sm text-right", style "margin-top" "-3px", style "margin-right" "-6px" ]
            [ if tile.value > 1 then
                text <| "x" ++ String.fromInt tile.value

              else
                text ""
            ]
        ]


skeletonSelectedTile : Html Msg
skeletonSelectedTile =
    div
        [ class "p-2 my-2 w-4 h-4 bg-blue-400 rounded-md" ]
        []


skeletonTile : Html Msg
skeletonTile =
    div
        [ class "p-2 my-2 w-12 h-12 bg-blue-600 rounded-md" ]
        []
