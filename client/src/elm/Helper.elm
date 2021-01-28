module Helper exposing (..)

import Constants exposing (maxConsonantOrVowel)
import Game exposing (Tile)
import Json.Decode as Json
import Task


mkCmd : msg -> Cmd msg
mkCmd msg =
    Task.perform (always msg) (Task.succeed msg)


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


toLetter : String -> Maybe Char
toLetter str =
    case String.uncons str of
        Just ( c, "" ) ->
            if Char.isAlpha c then
                Just (Char.toUpper c)

            else
                Nothing

        _ ->
            Nothing


fullWord : List Tile -> String
fullWord tiles =
    let
        wordList =
            List.map
                (\tile ->
                    tile.letter
                )
                tiles

        wordString =
            wordList
                |> String.fromList
                |> String.toLower
    in
    wordString
