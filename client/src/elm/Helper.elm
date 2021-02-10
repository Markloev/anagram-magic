module Helper exposing (..)

import Constants exposing (maxConsonantOrVowel)
import Game exposing (Game, Phase(..), SpecificRound(..), Tile)
import Html exposing (Html, div)
import Json.Encode as Encode
import Msg exposing (Msg(..))
import Task
import Time
import WebSocket exposing (ConnectionInfo, SocketStatus(..))


mkCmd : msg -> Cmd msg
mkCmd msg =
    Task.perform (always msg) (Task.succeed msg)


andThen : (model -> ( model, Cmd msg )) -> ( model, Cmd msg ) -> ( model, Cmd msg )
andThen fn ( model, cmd ) =
    let
        ( nextModel, nextCmd ) =
            fn model
    in
    ( nextModel, Cmd.batch [ cmd, nextCmd ] )


consonants : List Char
consonants =
    [ 'B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'X', 'Y', 'Z' ]


vowels : List Char
vowels =
    [ 'A', 'E', 'I', 'O', 'U' ]


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
                    Round FinalRound

                FinalRound ->
                    CompletedGame

        _ ->
            CompletedGame


getScore : Bool -> List Tile -> Int
getScore validWord tiles =
    if validWord then
        List.sum (List.map (\tile -> tile.value) tiles)

    else
        0


restartTimer : Int -> Game -> Game
restartTimer interval game =
    { game
        | currentTime = Time.millisToPosix 0
        , startedTime = Time.millisToPosix 0
        , timeInterval = interval
        , elapsedTime = 0
    }


repeatHtml : Int -> Html Msg -> List (Html Msg)
repeatHtml n html =
    if n <= 0 then
        []

    else
        List.append (repeatHtml (n - 1) html) [ html ]


wordToTiles : String -> List Tile
wordToTiles word =
    word
        |> String.toList
        |> List.indexedMap
            (\idx letter ->
                { letter = letter
                , value = 1
                , originalIndex = idx
                , hidden = False
                }
            )


unshuffleFinalWord : List Tile -> List Tile
unshuffleFinalWord tiles =
    List.sortBy (\tile -> tile.originalIndex) tiles


listTilesEncoder : List Tile -> Encode.Value
listTilesEncoder tiles =
    tiles |> Encode.list tileEncoder


tileEncoder : Tile -> Encode.Value
tileEncoder tile =
    Encode.object
        [ ( "letter", tile.letter |> Char.toCode |> Encode.int )
        , ( "value", tile.value |> Encode.int )
        , ( "originalIndex", tile.originalIndex |> Encode.int )
        , ( "hidden", tile.hidden |> Encode.bool )
        ]
