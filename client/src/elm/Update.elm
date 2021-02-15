module Update exposing (update)

import Base64
import Constants
import Game exposing (GameState(..), Phase(..), SpecificRound(..), initGame)
import Helper exposing (andThen, getConnectionInfo, getScore, listTilesEncoder, mkCmd, restartTimer, setNextPhase, toLetter, wordToTiles)
import Json.Decode as Decode
import List
import List.Extra as LE
import Msg exposing (Msg(..))
import Multiplayer
import Ports exposing (getRandomConsonant, getRandomTiles, getRandomVowel, shuffleTiles)
import Prelude exposing (iff)
import Time
import Types exposing (Model)
import WebSocket exposing (SocketStatus(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartSearch ->
            ( { model | gameState = Searching }
            , WebSocket.sendJsonString
                (getConnectionInfo model.socketInfo)
                (Multiplayer.basicEncoder "startSearch" model.playerId)
            )

        StopSearch ->
            ( { model | gameState = NotStarted }
            , WebSocket.sendJsonString
                (getConnectionInfo model.socketInfo)
                (Multiplayer.basicEncoder "stopSearch" model.playerId)
            )

        Tick game posix ->
            let
                ( updatedModel, cmd ) =
                    let
                        time =
                            game.time

                        secondsPassed =
                            Time.posixToMillis time.currentTime
                                - Time.posixToMillis time.startedTime
                                |> Time.millisToPosix
                                |> Time.toSecond Time.utc

                        ( updatedGame, timedCmd ) =
                            if secondsPassed == game.time.timeInterval then
                                let
                                    updatedTime =
                                        { time
                                            | currentTime = posix
                                            , startedTime = posix
                                            , paused = True
                                        }
                                in
                                ( { game
                                    | time = updatedTime
                                  }
                                , case game.phase of
                                    Waiting _ ->
                                        Cmd.none

                                    TileSelection _ ->
                                        GetRandom
                                            |> mkCmd

                                    Round _ ->
                                        Submit game
                                            |> mkCmd

                                    CompletedRound _ ->
                                        NextRound game
                                            |> mkCmd

                                    CompletedGame ->
                                        Cmd.none
                                )

                            else
                                let
                                    updatedTime =
                                        { time
                                            | currentTime = posix
                                        }
                                in
                                ( { game
                                    | time = updatedTime
                                  }
                                , Cmd.none
                                )
                    in
                    ( { model | gameState = Started updatedGame }, timedCmd )
            in
            ( updatedModel
            , cmd
            )

        KeyPressed key ->
            let
                cmd =
                    case model.gameState of
                        Started game ->
                            case game.phase of
                                Round _ ->
                                    if not game.waitingForUser then
                                        if key == " " then
                                            listTilesEncoder game.availableTiles
                                                |> shuffleTiles

                                        else if key == "Enter" then
                                            Submit game
                                                |> mkCmd

                                        else if key == "Backspace" then
                                            RemoveTileBackspace game
                                                |> mkCmd

                                        else
                                            let
                                                characterCmd =
                                                    case toLetter key of
                                                        Just k ->
                                                            KeyCharPressed game k
                                                                |> mkCmd

                                                        Nothing ->
                                                            Cmd.none
                                            in
                                            characterCmd

                                    else
                                        Cmd.none

                                TileSelection _ ->
                                    if key == "Enter" then
                                        GetRandom
                                            |> mkCmd

                                    else if key == "c" then
                                        GetConsonant game
                                            |> mkCmd

                                    else if key == "v" then
                                        GetVowel game
                                            |> mkCmd

                                    else
                                        Cmd.none

                                CompletedRound FinalRound ->
                                    if key == "Enter" then
                                        Continue game
                                            |> mkCmd

                                    else
                                        Cmd.none

                                CompletedRound _ ->
                                    if key == "Enter" then
                                        NextRound game
                                            |> mkCmd

                                    else
                                        Cmd.none

                                CompletedGame ->
                                    if key == "Enter" then
                                        EndGame
                                            |> mkCmd

                                    else
                                        Cmd.none

                                _ ->
                                    Cmd.none

                        NotStarted ->
                            if key == "Enter" then
                                StartSearch
                                    |> mkCmd

                            else
                                Cmd.none

                        Searching ->
                            if key == "Enter" then
                                StopSearch
                                    |> mkCmd

                            else
                                Cmd.none
            in
            ( model
            , cmd
            )

        KeyCharPressed game char ->
            let
                availableTiles =
                    List.filter
                        (\tile ->
                            tile.hidden == False && tile.letter == char
                        )
                        game.availableTiles

                updatedGame =
                    if List.length availableTiles > 0 then
                        let
                            possibleTiles =
                                List.sortBy
                                    (\tile -> tile.value)
                                    availableTiles

                            ( updatedSelectedTiles, updatedAvailableTiles ) =
                                case List.reverse possibleTiles |> List.head of
                                    Just t ->
                                        ( List.append
                                            game.selectedTiles
                                            [ t ]
                                        , LE.setIf
                                            (\tile ->
                                                tile.originalIndex == t.originalIndex
                                            )
                                            { t | hidden = True }
                                            game.availableTiles
                                        )

                                    Nothing ->
                                        ( game.selectedTiles
                                        , game.availableTiles
                                        )
                        in
                        { game
                            | selectedTiles = updatedSelectedTiles
                            , availableTiles = updatedAvailableTiles
                        }

                    else
                        game
            in
            ( { model | gameState = Started updatedGame }
            , WebSocket.sendJsonString
                (getConnectionInfo model.socketInfo)
                (Multiplayer.sharedTilesEncoder updatedGame.selectedTiles model.playerId)
            )

        GetConsonant game ->
            ( model
            , game.availableTiles
                |> listTilesEncoder
                |> getRandomConsonant
            )

        GetVowel game ->
            ( model
            , game.availableTiles
                |> listTilesEncoder
                |> getRandomVowel
            )

        GetRandom ->
            ( model
            , getRandomTiles ()
            )

        ReceiveRandomTiles game tiles ->
            let
                ( updatedGame, cmd ) =
                    case tiles of
                        Ok tilesResult ->
                            let
                                ( newGameState, multiplayerPhaseCmd ) =
                                    if List.length tilesResult == Constants.tileListMax then
                                        let
                                            shared =
                                                game.shared

                                            updatedShared =
                                                { shared
                                                    | waitingForUser = False
                                                }
                                        in
                                        ( { game
                                            | availableTiles = tilesResult
                                            , shared = updatedShared
                                            , phase = setNextPhase game.tileSelectionTurn game.phase
                                          }
                                            |> restartTimer Constants.roundTimeSeconds
                                        , WebSocket.sendJsonString
                                            (getConnectionInfo model.socketInfo)
                                            (Multiplayer.receiveTilesEncoder tilesResult model.playerId)
                                        )

                                    else
                                        ( { game | availableTiles = tilesResult }, Cmd.none )
                            in
                            ( newGameState, multiplayerPhaseCmd )

                        Err _ ->
                            ( game, Cmd.none )
            in
            ( { model | gameState = Started updatedGame }, cmd )

        ShuffleTiles game ->
            ( model
            , game.availableTiles
                |> listTilesEncoder
                |> shuffleTiles
            )

        ReceiveShuffledTiles game tiles ->
            let
                updatedGameState =
                    case tiles of
                        Ok tilesResult ->
                            { game | availableTiles = tilesResult }

                        Err _ ->
                            game
            in
            ( { model | gameState = Started updatedGameState }
            , Cmd.none
            )

        RemoveTileBackspace game ->
            let
                updatedGame =
                    if List.length game.selectedTiles > 0 then
                        let
                            tile =
                                game.selectedTiles
                                    |> List.reverse
                                    |> List.head

                            ( updatedAvailableTiles, updatedSelectedTiles ) =
                                case tile of
                                    Just t ->
                                        ( LE.setIf
                                            (\availableTile ->
                                                availableTile.originalIndex == t.originalIndex
                                            )
                                            { t | hidden = False }
                                            game.availableTiles
                                        , LE.removeAt
                                            (List.length game.selectedTiles - 1)
                                            game.selectedTiles
                                        )

                                    Nothing ->
                                        ( game.availableTiles
                                        , game.selectedTiles
                                        )
                        in
                        { game
                            | availableTiles = updatedAvailableTiles
                            , selectedTiles = updatedSelectedTiles
                        }

                    else
                        game
            in
            ( { model | gameState = Started updatedGame }
            , WebSocket.sendJsonString
                (getConnectionInfo model.socketInfo)
                (Multiplayer.sharedTilesEncoder updatedGame.selectedTiles model.playerId)
            )

        SelectTile game selectedIdx tile ->
            let
                updatedSelectedTiles =
                    List.append
                        game.selectedTiles
                        [ tile ]

                updatedAvailableTiles =
                    LE.setAt
                        selectedIdx
                        { tile | hidden = True }
                        game.availableTiles

                updatedGame =
                    { game
                        | selectedTiles = updatedSelectedTiles
                        , availableTiles = updatedAvailableTiles
                    }
            in
            ( { model | gameState = Started updatedGame }
            , WebSocket.sendJsonString
                (getConnectionInfo model.socketInfo)
                (Multiplayer.sharedTilesEncoder updatedSelectedTiles model.playerId)
            )

        RemoveTile game originalIndex selectedIdx ->
            let
                updatedAvailableTiles =
                    List.map
                        (\currentTile ->
                            if currentTile.originalIndex == originalIndex then
                                { currentTile | hidden = False }

                            else
                                currentTile
                        )
                        game.availableTiles

                updatedSelectedTiles =
                    LE.removeAt selectedIdx game.selectedTiles

                updatedGame =
                    { game
                        | selectedTiles = updatedSelectedTiles
                        , availableTiles = updatedAvailableTiles
                    }
            in
            ( { model | gameState = Started updatedGame }
            , WebSocket.sendJsonString
                (getConnectionInfo model.socketInfo)
                (Multiplayer.sharedTilesEncoder updatedSelectedTiles model.playerId)
            )

        Submit game ->
            let
                updatedGame =
                    { game | waitingForUser = True }
            in
            ( { model | gameState = Started updatedGame }
            , WebSocket.sendJsonString
                (getConnectionInfo model.socketInfo)
                (Multiplayer.submitTurnEncoder game.phase game.selectedTiles model.playerId)
            )

        NextRound game ->
            let
                updatedGame =
                    { game | waitingForUser = True }
            in
            ( { model | gameState = Started updatedGame }
            , WebSocket.sendJsonString
                (getConnectionInfo model.socketInfo)
                (Multiplayer.roundCompleteEncoder game.phase model.playerId)
            )

        Continue game ->
            let
                updatedGame =
                    { game
                        | phase = setNextPhase game.tileSelectionTurn game.phase
                    }
            in
            ( { model | gameState = Started updatedGame }
            , Cmd.none
            )

        EndGame ->
            ( { model | gameState = NotStarted }
            , WebSocket.sendJsonString
                (getConnectionInfo model.socketInfo)
                (Multiplayer.basicEncoder "endGame" model.playerId)
            )

        SocketConnect info ->
            ( { model | socketInfo = SocketConnected info }, Cmd.none )

        Msg.SocketClosed code reason ->
            ( { model
                | socketInfo = WebSocket.SocketClosed code reason
                , gameState = NotStarted
              }
            , Cmd.none
            )

        ReceivedString eventObject ->
            let
                ( newModel, cmd ) =
                    case Decode.decodeString Multiplayer.eventDecoder eventObject of
                        Err _ ->
                            ( model, Cmd.none )

                        Ok event ->
                            case event of
                                Multiplayer.PlayerFound opponentId tileSelectionTurn ->
                                    let
                                        updatedPhase =
                                            if tileSelectionTurn then
                                                TileSelection FirstRound

                                            else
                                                Waiting FirstRound

                                        updatedGame =
                                            initGame tileSelectionTurn opponentId updatedPhase
                                                |> restartTimer Constants.tileSelectionSeconds
                                    in
                                    ( { model | gameState = Started updatedGame }, Cmd.none )

                                Multiplayer.RoundComplete randomWord ->
                                    let
                                        ( availableTiles, shuffleCmd ) =
                                            case randomWord of
                                                Just r ->
                                                    let
                                                        decodedString =
                                                            case Base64.decode r of
                                                                Ok decStr ->
                                                                    decStr

                                                                Err _ ->
                                                                    ""
                                                    in
                                                    ( decodedString
                                                        |> wordToTiles
                                                    , decodedString
                                                        |> wordToTiles
                                                        |> listTilesEncoder
                                                        |> shuffleTiles
                                                    )

                                                Nothing ->
                                                    ( [], Cmd.none )

                                        updatedGameState =
                                            case model.gameState of
                                                Started game ->
                                                    let
                                                        shared =
                                                            game.shared

                                                        updatedShared =
                                                            { shared
                                                                | selectedTiles = []
                                                            }
                                                    in
                                                    Started
                                                        ({ game
                                                            | availableTiles = availableTiles
                                                            , selectedTiles = []
                                                            , waitingForUser = False
                                                            , phase = setNextPhase game.tileSelectionTurn game.phase
                                                            , shared = updatedShared
                                                         }
                                                            |> restartTimer Constants.tileSelectionSeconds
                                                        )

                                                _ ->
                                                    model.gameState
                                    in
                                    ( { model | gameState = updatedGameState }, shuffleCmd )

                                Multiplayer.ReceiveTiles availableTiles ->
                                    let
                                        updatedGameState =
                                            case model.gameState of
                                                Started game ->
                                                    Started
                                                        ({ game
                                                            | availableTiles = availableTiles
                                                            , waitingForUser = False
                                                            , phase = setNextPhase game.tileSelectionTurn game.phase
                                                         }
                                                            |> restartTimer Constants.roundTimeSeconds
                                                        )

                                                _ ->
                                                    model.gameState
                                    in
                                    ( { model | gameState = updatedGameState }, Cmd.none )

                                Multiplayer.ChangeTiles selectedWord ->
                                    let
                                        decodedWord =
                                            case Base64.decode selectedWord of
                                                Ok decStr ->
                                                    decStr

                                                Err _ ->
                                                    ""

                                        updatedGameState =
                                            case model.gameState of
                                                Started game ->
                                                    let
                                                        shared =
                                                            game.shared

                                                        updatedShared =
                                                            { shared
                                                                | selectedTiles = wordToTiles decodedWord
                                                            }
                                                    in
                                                    Started { game | shared = updatedShared }

                                                _ ->
                                                    model.gameState
                                    in
                                    ( { model | gameState = updatedGameState }, Cmd.none )

                                Multiplayer.SubmitTurn ->
                                    let
                                        updatedGameState =
                                            case model.gameState of
                                                Started game ->
                                                    let
                                                        shared =
                                                            game.shared

                                                        updatedShared =
                                                            { shared
                                                                | waitingForUser = True
                                                            }
                                                    in
                                                    Started { game | shared = updatedShared }

                                                _ ->
                                                    model.gameState
                                    in
                                    ( { model | gameState = updatedGameState }, Cmd.none )

                                Multiplayer.SubmitTurnComplete playerValidWord opponentValidWord ->
                                    let
                                        ( playerTotalScore, opponentTotalScore ) =
                                            case model.gameState of
                                                Started game ->
                                                    ( game.totalScore + getScore playerValidWord game.selectedTiles
                                                    , game.shared.totalScore + getScore opponentValidWord game.shared.selectedTiles
                                                    )

                                                _ ->
                                                    ( 0, 0 )

                                        updatedGameState =
                                            case model.gameState of
                                                Started game ->
                                                    let
                                                        shared =
                                                            game.shared

                                                        updatedShared =
                                                            { shared
                                                                | validWord = opponentValidWord
                                                                , totalScore = opponentTotalScore
                                                                , waitingForUser = False
                                                            }
                                                    in
                                                    Started
                                                        ({ game
                                                            | validWord = playerValidWord
                                                            , totalScore = playerTotalScore
                                                            , tileSelectionTurn = not game.tileSelectionTurn
                                                            , waitingForUser = False
                                                            , phase = setNextPhase (not game.tileSelectionTurn) game.phase
                                                            , shared = updatedShared
                                                         }
                                                            |> restartTimer Constants.roundResultSeconds
                                                        )

                                                _ ->
                                                    model.gameState
                                    in
                                    ( { model | gameState = updatedGameState }, Cmd.none )

                                Multiplayer.ForceEndGame ->
                                    let
                                        updatedGameState =
                                            case model.gameState of
                                                Started game ->
                                                    Started
                                                        ({ game
                                                            | errorOccurred = True
                                                            , phase = CompletedGame
                                                         }
                                                            |> restartTimer Constants.roundResultSeconds
                                                        )

                                                _ ->
                                                    model.gameState
                                    in
                                    ( { model | gameState = updatedGameState }, Cmd.none )
            in
            ( newModel, cmd )

        Error _ ->
            ( model, Cmd.none )
