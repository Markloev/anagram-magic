module Utils.CoreHelpers exposing (..)

import Game exposing (Phase(..), SpecificRound(..), Tile)
import Json.Encode as Encode
import Msg exposing (Msg(..))
import Task
import WebSocket.WebSocket exposing (ConnectionInfo, SocketStatus(..), initConnectionInfo)


addNone : m -> ( m, Cmd msg )
addNone m =
    ( m, Cmd.none )


mkCmd : msg -> Cmd msg
mkCmd msg =
    Task.perform (always msg) (Task.succeed msg)


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
            initConnectionInfo


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
