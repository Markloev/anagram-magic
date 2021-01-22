module Update exposing (update)

import Browser.Dom as Dom
import Constants exposing (maxConsonantOrVowel)
import Game exposing (GameState(..), Phase(..), Tile, initGame)
import Helper exposing (consonants, generatedConsonant, generatedTile, generatedVowel, hasMaxConsonants, hasMaxVowels, indexPair, return, vowels)
import Msg exposing (Msg(..))
import Prelude exposing (iff)
import Random
import Task
import Time
import Types exposing (Model)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DoNothing ->
            return model []

        FocusOn id ->
            ( model, Dom.focus id |> Task.attempt FocusResult )

        FocusResult _ ->
            ( model, Cmd.none )

        Tick posix ->
            let
                updatedGameState =
                    case model.gameState of
                        NotStarted ->
                            model.gameState

                        Started g ->
                            let
                                isStart =
                                    Time.posixToMillis g.startTime == 0

                                newGameState =
                                    { g
                                        | currentTime = posix
                                        , startTime = iff isStart posix g.startTime
                                    }
                            in
                            Started newGameState
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

        StartGame ->
            ( { model | gameState = Started initGame }, Cmd.none )

        GetConsonant game ->
            let
                cmd =
                    Random.generate (GenerateRandomConsonant game) (Random.int 0 20)
            in
            ( model, cmd )

        GetVowel game ->
            let
                cmd =
                    Random.generate (GenerateRandomVowel game) (Random.int 0 5)
            in
            ( model, cmd )

        GetRandom game ->
            let
                newRound =
                    game.round + 1

                updatedGameState =
                    { game
                        | selectedTiles = []
                        , round = newRound
                        , phase =
                            if newRound < 5 then
                                RegularRound

                            else
                                FinalRound
                    }

                cmd =
                    Random.generate (GenerateRandomLetter updatedGameState) indexPair
            in
            ( model, cmd )

        GenerateRandomLetter game indexes ->
            let
                updatedGameState =
                    { game | selectedTiles = generatedTile game.selectedTiles indexes :: game.selectedTiles }

                cmd =
                    if List.length updatedGameState.selectedTiles < 9 then
                        Random.generate (GenerateRandomLetter updatedGameState) indexPair

                    else
                        Cmd.none
            in
            ( { model | gameState = Started updatedGameState }, cmd )

        GenerateRandomConsonant game index ->
            let
                updatedGameState =
                    { game | selectedTiles = generatedConsonant index :: game.selectedTiles, round = game.round + 1 }

                finalGameState =
                    if List.length updatedGameState.selectedTiles == 9 then
                        { updatedGameState
                            | phase =
                                if updatedGameState.round < 5 then
                                    RegularRound

                                else
                                    FinalRound
                        }

                    else
                        updatedGameState
            in
            ( { model | gameState = Started finalGameState }, Cmd.none )

        GenerateRandomVowel game index ->
            let
                updatedGameState =
                    { game | selectedTiles = generatedVowel index :: game.selectedTiles, round = game.round + 1 }

                finalGameState =
                    if List.length updatedGameState.selectedTiles == 9 then
                        { updatedGameState
                            | phase =
                                if updatedGameState.round < 5 then
                                    RegularRound

                                else
                                    FinalRound
                        }

                    else
                        updatedGameState
            in
            ( { model | gameState = Started finalGameState }, Cmd.none )
