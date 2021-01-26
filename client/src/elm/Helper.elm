module Helper exposing (..)

import Array exposing (Array)
import Constants exposing (maxConsonantOrVowel)
import Element exposing (Attribute, Element)
import Game exposing (Tile)
import Html
import Html.Attributes as Attrs
import Html.Events
import Json.Decode as Json
import Maybe.Extra
import Msg exposing (Msg)
import Task


return : a -> List (Cmd b) -> ( a, Cmd b )
return model cmds =
    ( model, Cmd.batch cmds )


mkCmd : msg -> Cmd msg
mkCmd msg =
    Task.perform (always msg) (Task.succeed msg)


onRightClick : a -> Html.Attribute a
onRightClick message =
    Html.Events.custom
        "contextmenu"
    <|
        Json.succeed
            { message = message
            , stopPropagation = False
            , preventDefault = True
            }


whenJust : (a -> Element msg) -> Maybe a -> Element msg
whenJust =
    Maybe.Extra.unwrap Element.none


whenAttr : Bool -> Attribute msg -> Attribute msg
whenAttr bool =
    if bool then
        identity

    else
        Attrs.classList []
            |> Element.htmlAttribute
            |> always


when : Bool -> Element msg -> Element msg
when b =
    if b then
        identity

    else
        always Element.none


ifThenElse : Bool -> a -> a -> a
ifThenElse bool a b =
    if bool then
        a

    else
        b


mouseDownPreventDefault : Msg -> Html.Attribute Msg
mouseDownPreventDefault msg =
    Html.Events.custom "click"
        (Json.succeed
            { message = msg
            , stopPropagation = True
            , preventDefault = True
            }
        )


style : String -> String -> Attribute msg
style k v =
    Attrs.style k v
        |> Element.htmlAttribute


consonants : List Char
consonants =
    [ 'b', 'c', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'n', 'p', 'q', 'r', 's', 't', 'v', 'w', 'x', 'y', 'z' ]


vowels : List Char
vowels =
    [ 'a', 'e', 'i', 'o', 'u' ]


hasMaxConsonants : Array Tile -> Bool
hasMaxConsonants tiles =
    List.length (List.filter (\isConsonant -> isConsonant == True) (List.map (\tile -> List.member tile.letter consonants) <| Array.toList tiles)) >= maxConsonantOrVowel


hasMaxVowels : Array Tile -> Bool
hasMaxVowels tiles =
    List.length (List.filter (\isVowel -> isVowel == True) (List.map (\tile -> List.member tile.letter vowels) <| Array.toList tiles)) >= maxConsonantOrVowel
