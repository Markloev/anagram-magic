module Update exposing (update)

import Constants
import Game exposing (GameState(..), Phase(..), SpecificRound(..), initSharedGame)
import Helper exposing (getConnectionInfo, getScore, mkCmd, restartTimer, setNextPhase, toLetter)
import Json.Decode as Decode
import List
import List.Extra as LE
import Msg exposing (Msg(..))
import Multiplayer
import Ports exposing (encodeListTiles, getRandomConsonant, getRandomTiles, getRandomVowel, shuffleTiles)
import Prelude exposing (iff)
import Time
import Types exposing (Model)
import WebSocket exposing (SocketStatus(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DoNothing ->
            ( model
            , Cmd.none
            )

        StartSearch ->
            let
                game =
                    model.game

                updatedGame =
                    { game | gameState = Searching }
            in
            ( { model | game = updatedGame }
            , WebSocket.sendJsonString
                (getConnectionInfo model.socketInfo)
                (Multiplayer.basicEncoder "startSearch" model.game.playerId)
            )

        StopSearch ->
            let
                game =
                    model.game

                updatedGame =
                    { game | gameState = NotStarted }
            in
            ( { model | game = updatedGame }
            , WebSocket.sendJsonString
                (getConnectionInfo model.socketInfo)
                (Multiplayer.basicEncoder "stopSearch" model.game.playerId)
            )

        Tick posix ->
            let
                ( updatedModel, cmd ) =
                    case model.game.gameState of
                        Started sharedGame ->
                            let
                                isStart =
                                    Time.posixToMillis model.game.startedTime == 0

                                secondsPassed =
                                    Time.posixToMillis model.game.currentTime
                                        - Time.posixToMillis model.game.startedTime
                                        |> Time.millisToPosix
                                        |> Time.toSecond Time.utc

                                game =
                                    model.game

                                ( updatedGame, timedCmd ) =
                                    if secondsPassed == model.game.timeInterval then
                                        ( { game
                                            | currentTime = posix
                                            , startedTime = posix
                                          }
                                        , case sharedGame.phase of
                                            Waiting _ ->
                                                Cmd.none

                                            TileSelection _ ->
                                                GetRandom
                                                    |> mkCmd

                                            Round _ ->
                                                Submit
                                                    |> mkCmd

                                            CompletedRound _ ->
                                                NextRound sharedGame.phase
                                                    |> mkCmd

                                            CompletedGame ->
                                                Cmd.none
                                        )

                                    else
                                        ( { game
                                            | currentTime = posix
                                            , startedTime = iff isStart posix game.startedTime
                                          }
                                        , Cmd.none
                                        )
                            in
                            ( { model | game = updatedGame }, timedCmd )

                        _ ->
                            ( model, Cmd.none )
            in
            ( updatedModel
            , cmd
            )

        KeyPressed sharedGame key ->
            let
                cmd =
                    case sharedGame.phase of
                        Round _ ->
                            if key == " " then
                                encodeListTiles model.game.availableTiles
                                    |> shuffleTiles

                            else if key == "Enter" then
                                Submit
                                    |> mkCmd

                            else if key == "Backspace" then
                                RemoveTileBackspace
                                    |> mkCmd

                            else
                                let
                                    characterCmd =
                                        case toLetter key of
                                            Just k ->
                                                KeyCharPressed k
                                                    |> mkCmd

                                            Nothing ->
                                                Cmd.none
                                in
                                characterCmd

                        _ ->
                            Cmd.none
            in
            ( model
            , cmd
            )

        KeyCharPressed char ->
            let
                availableTiles =
                    List.filter
                        (\tile ->
                            tile.hidden == False && tile.letter == char
                        )
                        model.game.availableTiles

                game =
                    model.game

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
                                            model.game.selectedTiles
                                            [ t ]
                                        , LE.setIf
                                            (\tile ->
                                                tile.originalIndex == t.originalIndex
                                            )
                                            { t | hidden = True }
                                            model.game.availableTiles
                                        )

                                    Nothing ->
                                        ( model.game.selectedTiles
                                        , model.game.availableTiles
                                        )
                        in
                        { game
                            | selectedTiles = updatedSelectedTiles
                            , availableTiles = updatedAvailableTiles
                        }

                    else
                        game
            in
            ( { model | game = updatedGame }
            , WebSocket.sendJsonString
                (getConnectionInfo model.socketInfo)
                (Multiplayer.sharedTilesEncoder updatedGame.selectedTiles model.game.playerId)
            )

        GetConsonant ->
            ( model
            , encodeListTiles model.game.availableTiles
                |> getRandomConsonant
            )

        GetVowel ->
            ( model
            , encodeListTiles model.game.availableTiles
                |> getRandomVowel
            )

        GetRandom ->
            ( model
            , getRandomTiles ()
            )

        ReceiveRandomTiles sharedGame tiles ->
            let
                ( updatedGame, cmd ) =
                    case tiles of
                        Ok tilesResult ->
                            let
                                game =
                                    model.game

                                ( newGameState, multiplayerPhaseCmd ) =
                                    if List.length tilesResult == Constants.tileListMax then
                                        ( { game
                                            | availableTiles = tilesResult
                                            , gameState =
                                                Started
                                                    { sharedGame
                                                        | phase = setNextPhase model.game.tileSelectionTurn sharedGame.phase
                                                        , turnSubmitted = False
                                                    }
                                          }
                                            |> restartTimer Constants.roundTimeSeconds
                                        , WebSocket.sendJsonString
                                            (getConnectionInfo model.socketInfo)
                                            (Multiplayer.receiveTilesEncoder tilesResult model.game.playerId)
                                        )

                                    else
                                        ( { game | availableTiles = tilesResult }, Cmd.none )
                            in
                            ( newGameState, multiplayerPhaseCmd )

                        Err _ ->
                            ( model.game, Cmd.none )
            in
            ( { model | game = updatedGame }, cmd )

        ShuffleTiles ->
            ( model
            , encodeListTiles model.game.availableTiles
                |> shuffleTiles
            )

        ReceiveShuffledTiles tiles ->
            let
                game =
                    model.game

                updatedGame =
                    case tiles of
                        Ok tilesResult ->
                            { game | availableTiles = tilesResult }

                        Err _ ->
                            game
            in
            ( { model | game = updatedGame }
            , Cmd.none
            )

        RemoveTileBackspace ->
            let
                game =
                    model.game

                updatedGame =
                    if List.length model.game.selectedTiles > 0 then
                        let
                            tile =
                                model.game.selectedTiles
                                    |> List.reverse
                                    |> List.head

                            ( updatedAvailableTiles, updatedSelectedTiles ) =
                                case tile of
                                    Just t ->
                                        ( LE.setAt
                                            t.originalIndex
                                            { t | hidden = False }
                                            model.game.availableTiles
                                        , LE.removeAt
                                            (List.length model.game.selectedTiles - 1)
                                            model.game.selectedTiles
                                        )

                                    Nothing ->
                                        ( model.game.availableTiles
                                        , model.game.selectedTiles
                                        )
                        in
                        { game
                            | availableTiles = updatedAvailableTiles
                            , selectedTiles = updatedSelectedTiles
                        }

                    else
                        game
            in
            ( { model | game = updatedGame }
            , WebSocket.sendJsonString
                (getConnectionInfo model.socketInfo)
                (Multiplayer.sharedTilesEncoder updatedGame.selectedTiles model.game.playerId)
            )

        SelectTile selectedIdx tile ->
            let
                game =
                    model.game

                updatedSelectedTiles =
                    List.append
                        model.game.selectedTiles
                        [ tile ]

                updatedAvailableTiles =
                    LE.setAt
                        selectedIdx
                        { tile | hidden = True }
                        model.game.availableTiles

                updatedGame =
                    { game
                        | selectedTiles = updatedSelectedTiles
                        , availableTiles = updatedAvailableTiles
                    }
            in
            ( { model | game = updatedGame }
            , WebSocket.sendJsonString
                (getConnectionInfo model.socketInfo)
                (Multiplayer.sharedTilesEncoder updatedSelectedTiles model.game.playerId)
            )

        RemoveTile originalIndex selectedIdx ->
            let
                game =
                    model.game

                updatedAvailableTiles =
                    List.map
                        (\currentTile ->
                            if currentTile.originalIndex == originalIndex then
                                { currentTile | hidden = False }

                            else
                                currentTile
                        )
                        model.game.availableTiles

                updatedSelectedTiles =
                    LE.removeAt selectedIdx model.game.selectedTiles

                updatedGame =
                    { game
                        | selectedTiles = updatedSelectedTiles
                        , availableTiles = updatedAvailableTiles
                    }
            in
            ( { model | game = updatedGame }
            , WebSocket.sendJsonString
                (getConnectionInfo model.socketInfo)
                (Multiplayer.sharedTilesEncoder updatedSelectedTiles model.game.playerId)
            )

        Submit ->
            let
                game =
                    model.game

                updatedGame =
                    { game | turnSubmitted = True }
            in
            ( { model | game = updatedGame }
            , WebSocket.sendJsonString
                (getConnectionInfo model.socketInfo)
                (Multiplayer.submitTurnEncoder model.game.selectedTiles model.game.playerId)
            )

        NextRound phase ->
            ( model
            , WebSocket.sendJsonString
                (getConnectionInfo model.socketInfo)
                (Multiplayer.roundCompleteEncoder phase model.game.playerId)
            )

        SocketConnect info ->
            ( { model | socketInfo = SocketConnected info }, Cmd.none )

        Msg.SocketClosed code reason ->
            let
                game =
                    model.game

                updatedGame =
                    { game | gameState = NotStarted }
            in
            ( { model
                | socketInfo = WebSocket.SocketClosed code reason
                , game = updatedGame
              }
            , Cmd.none
            )

        ReceivedString eventObject ->
            let
                newModel =
                    case Decode.decodeString Multiplayer.eventDecoder eventObject of
                        Err errMsg ->
                            let
                                _ =
                                    Debug.log "Multiplayer Error" errMsg
                            in
                            model

                        Ok event ->
                            case event of
                                Multiplayer.PlayerFound opponentId tileSelectionTurn ->
                                    let
                                        updatedPhase =
                                            if tileSelectionTurn then
                                                TileSelection FirstRound

                                            else
                                                Waiting FirstRound

                                        game =
                                            model.game

                                        updatedGame =
                                            { game
                                                | tileSelectionTurn = tileSelectionTurn
                                                , gameState = Started (initSharedGame opponentId updatedPhase)
                                            }
                                                |> restartTimer Constants.tileSelectionSeconds
                                    in
                                    { model | game = updatedGame }

                                Multiplayer.RoundComplete randomWord ->
                                    let
                                        game =
                                            model.game

                                        updatedGame =
                                            case model.game.gameState of
                                                Started sharedGameState ->
                                                    { game
                                                        | availableTiles = []
                                                        , selectedTiles = []
                                                        , randomWord =
                                                            case randomWord of
                                                                Just r ->
                                                                    r

                                                                Nothing ->
                                                                    ""
                                                        , gameState =
                                                            Started
                                                                { sharedGameState
                                                                    | phase = setNextPhase model.game.tileSelectionTurn sharedGameState.phase
                                                                    , selectedTiles = []
                                                                }
                                                    }
                                                        |> restartTimer Constants.tileSelectionSeconds

                                                _ ->
                                                    model.game
                                    in
                                    { model | game = updatedGame }

                                Multiplayer.ReceiveTiles availableTiles ->
                                    let
                                        game =
                                            model.game

                                        updatedGame =
                                            case model.game.gameState of
                                                Started sharedGameState ->
                                                    { game
                                                        | availableTiles = availableTiles
                                                        , gameState =
                                                            Started
                                                                { sharedGameState
                                                                    | phase = setNextPhase model.game.tileSelectionTurn sharedGameState.phase
                                                                }
                                                    }
                                                        |> restartTimer Constants.roundTimeSeconds

                                                _ ->
                                                    model.game
                                    in
                                    { model | game = updatedGame }

                                Multiplayer.ChangeTiles selectedTiles ->
                                    let
                                        game =
                                            model.game

                                        updatedGame =
                                            case model.game.gameState of
                                                Started sharedGameState ->
                                                    { game | gameState = Started { sharedGameState | selectedTiles = selectedTiles } }

                                                _ ->
                                                    model.game
                                    in
                                    { model | game = updatedGame }

                                Multiplayer.SubmitTurnComplete playerValidWord opponentValidWord ->
                                    let
                                        game =
                                            model.game

                                        ( playerTotalScore, opponentTotalScore ) =
                                            case game.gameState of
                                                Started sharedGame ->
                                                    ( if playerValidWord then
                                                        game.totalScore + getScore game.selectedTiles

                                                      else
                                                        game.totalScore
                                                    , if opponentValidWord then
                                                        sharedGame.totalScore + getScore sharedGame.selectedTiles

                                                      else
                                                        sharedGame.totalScore
                                                    )

                                                _ ->
                                                    ( 0, 0 )

                                        updatedGame =
                                            case model.game.gameState of
                                                Started sharedGameState ->
                                                    { game
                                                        | validWord = playerValidWord
                                                        , totalScore = playerTotalScore
                                                        , tileSelectionTurn = not model.game.tileSelectionTurn
                                                        , gameState =
                                                            Started
                                                                { sharedGameState
                                                                    | validWord = opponentValidWord
                                                                    , totalScore = opponentTotalScore
                                                                    , phase = setNextPhase (not model.game.tileSelectionTurn) sharedGameState.phase
                                                                }
                                                    }
                                                        |> restartTimer Constants.roundResultSeconds

                                                _ ->
                                                    model.game
                                    in
                                    { model | game = updatedGame }

                                Multiplayer.SubmitTurn ->
                                    let
                                        game =
                                            model.game

                                        updatedGame =
                                            case model.game.gameState of
                                                Started sharedGameState ->
                                                    { game
                                                        | gameState =
                                                            Started
                                                                { sharedGameState | turnSubmitted = True }
                                                    }

                                                _ ->
                                                    model.game
                                    in
                                    { model | game = updatedGame }
            in
            ( newModel, Cmd.none )

        Error errMsg ->
            let
                _ =
                    Debug.log "Error" errMsg
            in
            ( model, Cmd.none )
