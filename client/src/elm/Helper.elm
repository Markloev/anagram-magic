module Helper exposing (..)

import Constants exposing (maxConsonantOrVowel)
import Game exposing (Phase(..), SpecificRound(..), Tile)
import Task
import WebSocket exposing (ConnectionInfo, SocketStatus(..))


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


getConnectionInfo : SocketStatus -> ConnectionInfo
getConnectionInfo socketInfo =
    case socketInfo of
        SocketConnected info ->
            info

        _ ->
            Debug.todo "Not connected to server."


setNextPhase : Bool -> Phase -> Phase
setNextPhase tileSelectionTurn phase =
    let
        selectionPhase =
            if tileSelectionTurn then
                TileSelection

            else
                Waiting
    in
    case phase of
        Waiting round ->
            case round of
                FirstRound ->
                    Round FirstRound

                SecondRound ->
                    Round SecondRound

                ThirdRound ->
                    Round ThirdRound

                FourthRound ->
                    Round FourthRound

                FinalRound ->
                    Round FinalRound

        TileSelection round ->
            case round of
                FirstRound ->
                    Round FirstRound

                SecondRound ->
                    Round SecondRound

                ThirdRound ->
                    Round ThirdRound

                FourthRound ->
                    Round FourthRound

                FinalRound ->
                    Round FinalRound

        Round round ->
            case round of
                FirstRound ->
                    CompletedRound FirstRound

                SecondRound ->
                    CompletedRound SecondRound

                ThirdRound ->
                    CompletedRound ThirdRound

                FourthRound ->
                    CompletedRound FourthRound

                FinalRound ->
                    CompletedRound FinalRound

        CompletedRound round ->
            case round of
                FirstRound ->
                    selectionPhase SecondRound

                SecondRound ->
                    selectionPhase ThirdRound

                ThirdRound ->
                    selectionPhase FourthRound

                FourthRound ->
                    selectionPhase FinalRound

                FinalRound ->
                    CompletedGame

        CompletedGame ->
            CompletedGame
