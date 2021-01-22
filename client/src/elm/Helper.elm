module Helper exposing (..)

import Array
import Constants exposing (maxConsonantOrVowel)
import Element exposing (Attribute, Element)
import Game exposing (Tile)
import Html
import Html.Attributes as Attrs exposing (style)
import Html.Events
import Json.Decode as Json
import Maybe.Extra
import Msg exposing (Msg)
import Random
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



hasMaxConsonants : List Tile -> Bool
hasMaxConsonants tiles =
    List.length (List.filter (\isConsonant -> isConsonant == True) (List.map (\tile -> List.member tile.letter consonants) tiles)) >= maxConsonantOrVowel


hasMaxVowels : List Tile -> Bool
hasMaxVowels tiles =
    List.length (List.filter (\isVowel -> isVowel == True) (List.map (\tile -> List.member tile.letter vowels) tiles)) >= maxConsonantOrVowel


indexPair : Random.Generator ( Int, Int )
indexPair =
    let
        consonantOrVowel =
            Random.int 0 1
                
        letterIndex =
            consonantOrVowel
                |> Random.andThen (\index -> 
                    if index == 0 then
                        Random.int 0 20
                    
                    else
                        Random.int 0 5
                    )
    in
    Random.pair consonantOrVowel letterIndex


generatedTile : List Tile -> (Int, Int) -> Tile
generatedTile selectedTiles indexes =
    if Tuple.first indexes == 0 then
        if hasMaxConsonants selectedTiles then
            { letter = Maybe.withDefault 'a' <| Array.get (Tuple.second indexes) (Array.fromList vowels), value = 1 }
        
        else
            { letter = Maybe.withDefault 'b' <| Array.get (Tuple.second indexes) (Array.fromList consonants), value = 1 }

    else
        if hasMaxVowels selectedTiles then
            { letter = Maybe.withDefault 'b' <| Array.get (Tuple.second indexes) (Array.fromList consonants), value = 1 }
        
        else
            { letter = Maybe.withDefault 'a' <| Array.get (Tuple.second indexes) (Array.fromList vowels), value = 1 }


generatedConsonant : Int -> Tile
generatedConsonant index =
    { letter = Maybe.withDefault 'b' <| Array.get index (Array.fromList consonants), value = 1 }


generatedVowel : Int -> Tile
generatedVowel index =
    { letter = Maybe.withDefault 'a' <| Array.get index (Array.fromList vowels), value = 1 }