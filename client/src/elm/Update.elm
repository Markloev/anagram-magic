module Update exposing (update)

import Base64
import Constants exposing (roundTimeSeconds, tileListMax, tileSelectionSeconds)
import Game exposing (GameState(..), Phase(..), SpecificRound(..), initSharedGame)
import Helper exposing (fullWord, getConnectionInfo, mkCmd, setNextPhase, toLetter)
import Json.Decode as Decode
import List
import List.Extra as LE
import Msg exposing (Msg(..))
import Multiplayer
import Ports exposing (encodeListTiles, getRandomConsonant, getRandomTiles, getRandomVowel, shuffleTiles)
import Prelude exposing (iff)
import Rest exposing (getWordValidity)
import Time
import Types exposing (Model)
import WebSocket exposing (SocketStatus(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DoNothing ->
            ( model, Cmd.none )

        Tick posix ->
            let
                updatedGame =
                    case model.game.gameState of
                        Started sharedGame ->
                            let
                                isStart =
                                    Time.posixToMillis model.game.startTime == 0

                                secondsPassed =
                                    Time.toSecond Time.utc (Time.millisToPosix (Time.posixToMillis model.game.currentTime - Time.posixToMillis model.game.startTime))

                                game =
                                    model.game

                                newGame =
                                    case sharedGame.phase of
                                        TileSelection _ ->
                                            let
                                                finalGame =
                                                    if secondsPassed == tileSelectionSeconds then
                                                        { game
                                                            | currentTime = posix
                                                            , startTime = posix
                                                            , gameState =
                                                                Started
                                                                    { sharedGame
                                                                        | phase = setNextPhase sharedGame.phase
                                                                    }
                                                        }

                                                    else
                                                        { game | currentTime = posix, startTime = iff isStart posix game.startTime }
                                            in
                                            finalGame

                                        _ ->
                                            let
                                                finalGame =
                                                    if secondsPassed == roundTimeSeconds then
                                                        { game
                                                            | currentTime = posix
                                                            , startTime = posix
                                                            , gameState =
                                                                Started
                                                                    { sharedGame
                                                                        | phase = setNextPhase sharedGame.phase
                                                                    }
                                                        }

                                                    else
                                                        { game | currentTime = posix, startTime = iff isStart posix game.startTime }
                                            in
                                            finalGame
                            in
                            newGame

                        _ ->
                            model.game
            in
            ( { model | game = updatedGame }, Cmd.none )

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
            ( model, cmd )

        KeyCharPressed char ->
            let
                availableTiles =
                    List.filter (\tile -> tile.hidden == False && tile.letter == char) model.game.availableTiles

                game =
                    model.game

                updatedGame =
                    if List.length availableTiles > 0 then
                        let
                            possibleTiles =
                                List.sortBy (\tile -> tile.value) availableTiles

                            ( updatedSelectedTiles, updatedAvailableTiles ) =
                                case List.reverse possibleTiles |> List.head of
                                    Just t ->
                                        ( List.append model.game.selectedTiles [ t ], LE.setIf (\tile -> tile.originalIndex == t.originalIndex) { t | hidden = True } model.game.availableTiles )

                                    Nothing ->
                                        ( model.game.selectedTiles, model.game.availableTiles )
                        in
                        { game | selectedTiles = updatedSelectedTiles, availableTiles = updatedAvailableTiles }

                    else
                        game
            in
            ( { model | game = updatedGame }, Cmd.none )

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
                                        ( LE.setAt t.originalIndex { t | hidden = False } model.game.availableTiles
                                        , LE.removeAt (List.length model.game.selectedTiles - 1) model.game.selectedTiles
                                        )

                                    Nothing ->
                                        ( model.game.availableTiles, model.game.selectedTiles )
                        in
                        { game | availableTiles = updatedAvailableTiles, selectedTiles = updatedSelectedTiles }

                    else
                        game
            in
            ( { model | game = updatedGame }, Cmd.none )

        GetConsonant ->
            ( model, encodeListTiles model.game.availableTiles |> getRandomConsonant )

        GetVowel ->
            ( model, encodeListTiles model.game.availableTiles |> getRandomVowel )

        GetRandom ->
            ( model, getRandomTiles () )

        ShuffleTiles ->
            ( model, encodeListTiles model.game.availableTiles |> shuffleTiles )

        ReceiveRandomTiles sharedGame tiles ->
            let
                ( updatedGame, cmd ) =
                    case tiles of
                        Ok tilesResult ->
                            let
                                game =
                                    model.game

                                ( newGameState, multiplayerPhaseCmd ) =
                                    if List.length tilesResult == tileListMax then
                                        ( { game
                                            | availableTiles = tilesResult
                                            , gameState =
                                                Started
                                                    { sharedGame
                                                        | phase = setNextPhase sharedGame.phase
                                                        , isSubmitted = False
                                                    }
                                          }
                                        , WebSocket.sendJsonString
                                            (getConnectionInfo model.socketInfo)
                                            (Multiplayer.changePhaseEncoder model.game.playerId)
                                        )

                                    else
                                        ( { game | availableTiles = tilesResult }, Cmd.none )
                            in
                            ( newGameState, multiplayerPhaseCmd )

                        Err _ ->
                            ( model.game, Cmd.none )
            in
            ( { model | game = updatedGame }, cmd )

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
            ( { model | game = updatedGame }, Cmd.none )

        SelectTile selectedIdx tile ->
            let
                game =
                    model.game

                updatedSelectedTiles =
                    List.append model.game.selectedTiles [ tile ]

                updatedAvailableTiles =
                    LE.setAt selectedIdx { tile | hidden = True } model.game.availableTiles

                updatedGame =
                    { game | selectedTiles = updatedSelectedTiles, availableTiles = updatedAvailableTiles }
            in
            ( { model | game = updatedGame }, Cmd.none )

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
                    { game | selectedTiles = updatedSelectedTiles, availableTiles = updatedAvailableTiles }
            in
            ( { model | game = updatedGame }, Cmd.none )

        Submit ->
            let
                game =
                    model.game

                updatedGame =
                    { game | isSubmitted = True }
            in
            ( { model | game = updatedGame }, fullWord game.selectedTiles |> getWordValidity )

        GetWordValidityResponse res ->
            ( model, Cmd.none )

        GetRandomWordResponse res ->
            let
                word =
                    case res of
                        Ok encWord ->
                            let
                                decWord =
                                    Base64.decode encWord
                            in
                            case decWord of
                                Ok decodedWord ->
                                    decodedWord

                                Err _ ->
                                    ""

                        Err _ ->
                            ""
            in
            ( model, Cmd.none )

        SocketConnect info ->
            ( { model | socketInfo = SocketConnected info }, Cmd.none )

        Msg.SocketClosed code reason ->
            let
                game =
                    model.game

                updatedGame =
                    { game | gameState = NotStarted (Maybe.withDefault "No connection to server..." reason) }
            in
            ( { model
                | socketInfo = WebSocket.SocketClosed code reason
                , game = updatedGame
              }
            , Cmd.none
            )

        ReceivedString eventObject ->
            let
                _ =
                    Debug.log "RECEIVED" eventObject

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
                                            { game | gameState = Started (initSharedGame opponentId updatedPhase) }
                                    in
                                    { model | game = updatedGame }

                                Multiplayer.ChangePhase ->
                                    let
                                        game =
                                            model.game

                                        updatedGame =
                                            case model.game.gameState of
                                                Started sharedGameState ->
                                                    { game | gameState = Started { sharedGameState | phase = setNextPhase sharedGameState.phase } }

                                                _ ->
                                                    model.game
                                    in
                                    { model | game = updatedGame }

                                Multiplayer.Searching ->
                                    model
            in
            ( newModel, Cmd.none )

        Error errMsg ->
            let
                _ =
                    Debug.log "Error" errMsg
            in
            ( model, Cmd.none )

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
                (Multiplayer.searchingEncoder model.game.playerId)
            )
