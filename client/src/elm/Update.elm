module Update exposing (update)

import Base64
import Constants exposing (roundTimeSeconds, tileListMax, tileSelectionSeconds, totalRounds)
import Game exposing (GameState(..), Phase(..), initGame)
import Helper exposing (fullWord, getConnectionTicket, mkCmd, toLetter)
import List
import List.Extra as LE
import Msg exposing (Msg(..))
import Ports exposing (encodeListTiles, getRandomConsonant, getRandomTiles, getRandomVowel, shuffleTiles, toSocket)
import Prelude exposing (iff)
import Rest exposing (getRandomWord, getWordValidity)
import Time
import Types exposing (Model)
import WebSocket exposing (ConnectionInfo, SocketStatus(..))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DoNothing ->
            ( model, Cmd.none )

        Tick posix ->
            let
                updatedGameState =
                    case model.gameState of
                        NotStarted t ->
                            model.gameState

                        Started g ->
                            let
                                isStart =
                                    Time.posixToMillis g.startTime == 0

                                secondsPassed =
                                    Time.toSecond Time.utc (Time.millisToPosix (Time.posixToMillis g.currentTime - Time.posixToMillis g.startTime))

                                newGameState =
                                    case g.phase of
                                        TileSelection ->
                                            let
                                                finalGameState =
                                                    if secondsPassed == tileSelectionSeconds then
                                                        { g
                                                            | phase =
                                                                if g.round < totalRounds then
                                                                    RegularRound

                                                                else
                                                                    FinalRound

                                                            -- , availableTiles =
                                                            --     if g.round < totalRounds then
                                                            --         if List.length g.availableTiles < tileListMax then
                                                            , currentTime = posix
                                                            , startTime = posix
                                                        }

                                                    else
                                                        { g | currentTime = posix, startTime = iff isStart posix g.startTime }
                                            in
                                            finalGameState

                                        _ ->
                                            let
                                                newRound =
                                                    g.round + 1

                                                finalGameState =
                                                    if secondsPassed == roundTimeSeconds then
                                                        { g
                                                            | round = newRound
                                                            , phase =
                                                                if newRound < totalRounds then
                                                                    TileSelection

                                                                else
                                                                    Completed
                                                            , currentTime = posix
                                                            , startTime = posix
                                                        }

                                                    else
                                                        { g | currentTime = posix, startTime = iff isStart posix g.startTime }
                                            in
                                            finalGameState
                            in
                            Started newGameState
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

        KeyPressed game key ->
            let
                cmd =
                    if game.phase /= TileSelection then
                        if key == " " then
                            encodeListTiles game.availableTiles
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
            in
            ( model, cmd )

        KeyCharPressed game char ->
            let
                availableTiles =
                    List.filter (\tile -> tile.hidden == False && tile.letter == char) game.availableTiles

                updatedGameState =
                    if List.length availableTiles > 0 then
                        let
                            possibleTiles =
                                List.sortBy (\tile -> tile.value) availableTiles

                            ( updatedSelectedTiles, updatedAvailableTiles ) =
                                case List.reverse possibleTiles |> List.head of
                                    Just t ->
                                        ( List.append game.selectedTiles [ t ], LE.setIf (\tile -> tile.originalIndex == t.originalIndex) { t | hidden = True } game.availableTiles )

                                    Nothing ->
                                        ( game.selectedTiles, game.availableTiles )
                        in
                        Started { game | selectedTiles = updatedSelectedTiles, availableTiles = updatedAvailableTiles }

                    else
                        Started game
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

        RemoveTileBackspace game ->
            let
                updatedGameState =
                    if List.length game.selectedTiles > 0 then
                        let
                            tile =
                                game.selectedTiles
                                    |> List.reverse
                                    |> List.head

                            ( updatedAvailableTiles, updatedSelectedTiles ) =
                                case tile of
                                    Just t ->
                                        ( LE.setAt t.originalIndex { t | hidden = False } game.availableTiles
                                        , LE.removeAt (List.length game.selectedTiles - 1) game.selectedTiles
                                        )

                                    Nothing ->
                                        ( game.availableTiles, game.selectedTiles )
                        in
                        Started { game | availableTiles = updatedAvailableTiles, selectedTiles = updatedSelectedTiles }

                    else
                        Started game
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

        StartGame ->
            ( { model | gameState = Started initGame }, Cmd.none )

        GetConsonant game ->
            ( model, encodeListTiles game.availableTiles |> getRandomConsonant )

        GetVowel game ->
            ( model, encodeListTiles game.availableTiles |> getRandomVowel )

        GetRandom ->
            ( model, getRandomTiles () )

        ShuffleTiles game ->
            ( model, encodeListTiles game.availableTiles |> shuffleTiles )

        ReceiveRandomTiles game tiles ->
            let
                updatedGameState =
                    case tiles of
                        Ok tilesResult ->
                            let
                                newGameState =
                                    if List.length tilesResult == tileListMax then
                                        Started
                                            { game
                                                | phase =
                                                    if game.round < totalRounds then
                                                        RegularRound

                                                    else
                                                        FinalRound
                                                , availableTiles = tilesResult
                                                , isSubmitted = False
                                            }

                                    else
                                        Started { game | availableTiles = tilesResult }
                            in
                            newGameState

                        Err _ ->
                            Started game
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

        ReceiveShuffledTiles game tiles ->
            let
                updatedGameState =
                    case tiles of
                        Ok tilesResult ->
                            Started { game | availableTiles = tilesResult }

                        Err _ ->
                            Started game
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

        SelectTile game selectedIdx tile ->
            let
                updatedSelectedTiles =
                    List.append game.selectedTiles [ tile ]

                updatedAvailableTiles =
                    LE.setAt selectedIdx { tile | hidden = True } game.availableTiles

                updatedGameState =
                    Started { game | selectedTiles = updatedSelectedTiles, availableTiles = updatedAvailableTiles }
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

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

                updatedGameState =
                    Started { game | selectedTiles = updatedSelectedTiles, availableTiles = updatedAvailableTiles }
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

        Submit game ->
            let
                updatedGameState =
                    Started { game | isSubmitted = True }
            in
            ( { model | gameState = updatedGameState }, fullWord game.selectedTiles |> getWordValidity )

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

        ReceiveSocketMessage message ->
            ( { model | socketMessage = message }, Cmd.none )

        GotTicket result ->
            let
                newModel =
                    case result of
                        Ok ticket ->
                            { model | socketInfo = Requested ticket }

                        Err _ ->
                            { model | gameState = NotStarted "Failed to receive ticket from server" }
            in
            ( newModel
            , WebSocket.connect "ws://localhost:8080/sockets" []
            )

        SocketConnect info ->
            let
                sds =
                    Debug.log "HERE" "WE HERE"
            in
            ( { model | socketInfo = SocketConnected info }
            , WebSocket.sendString info (getConnectionTicket model.socketInfo)
            )

        Msg.SocketClosed code reason ->
            ( { model
                | socketInfo = WebSocket.SocketClosed code reason
                , gameState = NotStarted (Maybe.withDefault "No connection to server..." reason)
              }
            , Cmd.none
            )

        ReceivedString eventMessage ->
            let
                sds =
                    Debug.log "RECEIVED" eventMessage
            in
            ( { model | socketMessage = eventMessage }, Cmd.none )

        Error errMsg ->
            let
                _ =
                    Debug.log "Error" errMsg
            in
            ( model, Cmd.none )
