module Update exposing (update)

import Browser.Dom as Dom
import Game exposing (GameState(..), Phase(..), initGame)
import List.Extra as LE
import Msg exposing (Msg(..))
import Ports exposing (encodeListTiles, getRandomConsonant, getRandomTiles, getRandomVowel, shuffleTiles)
import Prelude exposing (iff)
import Task
import Time
import Types exposing (Model)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DoNothing ->
            ( model, Cmd.none )

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
            ( model, getRandomConsonant <| encodeListTiles game.availableTiles )

        GetVowel game ->
            ( model, getRandomVowel <| encodeListTiles game.availableTiles )

        GetRandom ->
            ( model, getRandomTiles () )

        ShuffleTiles game ->
            ( model, shuffleTiles <| encodeListTiles game.availableTiles )

        ReceiveRandomTiles gameState tiles ->
            let
                updatedGameState =
                    case gameState of
                        Started game ->
                            case tiles of
                                Ok tilesResult ->
                                    let
                                        newRound =
                                            game.round + 1

                                        newGameState =
                                            if List.length tilesResult == 9 then
                                                Started
                                                    { game
                                                        | round = newRound
                                                        , phase =
                                                            if newRound < 5 then
                                                                RegularRound

                                                            else
                                                                FinalRound
                                                        , availableTiles = tilesResult
                                                    }

                                            else
                                                Started { game | availableTiles = tilesResult }
                                    in
                                    newGameState

                                Err _ ->
                                    gameState

                        NotStarted ->
                            gameState
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

        ReceiveShuffledTiles gameState tiles ->
            let
                updatedGameState =
                    case gameState of
                        Started game ->
                            case tiles of
                                Ok tilesResult ->
                                    Started { game | availableTiles = tilesResult }

                                Err _ ->
                                    gameState

                        NotStarted ->
                            gameState
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

        SelectTile game idx ->
            let
                updatedSelectedTiles =
                    game.selectedTiles ++ [ Maybe.withDefault { letter = 'A', value = 1 } (LE.getAt idx game.availableTiles) ]

                updatedAvailableTiles =
                    LE.removeAt idx game.availableTiles

                updatedGameState =
                    Started { game | selectedTiles = updatedSelectedTiles, availableTiles = updatedAvailableTiles }
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

        RemoveTile game idx ->
            let
                updatedAvailableTiles =
                    game.availableTiles ++ [ Maybe.withDefault { letter = 'A', value = 1 } (LE.getAt idx game.selectedTiles) ]

                updatedSelectedTiles =
                    LE.removeAt idx game.selectedTiles

                updatedGameState =
                    Started { game | selectedTiles = updatedSelectedTiles, availableTiles = updatedAvailableTiles }
            in
            ( { model | gameState = updatedGameState }, Cmd.none )
