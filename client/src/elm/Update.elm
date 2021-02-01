module Update exposing (update)

import Base64
import Constants exposing (roundTimeSeconds, tileListMax, tileSelectionSeconds, totalRounds)
import Game exposing (GameState(..), Phase(..), initGame, initSharedGame)
import Helper exposing (fullWord, getConnectionInfo, mkCmd, toLetter)
import Json.Decode as Decode
import List
import List.Extra as LE
import Msg exposing (Msg(..))
import Multiplayer
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

                        Searching ->
                            model.gameState

                        Started g sg ->
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
                            Started newGameState sg
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

        KeyPressed game sharedGame key ->
            let
                cmd =
                    if game.phase /= TileSelection then
                        if key == " " then
                            encodeListTiles game.availableTiles
                                |> shuffleTiles

                        else if key == "Enter" then
                            Submit game sharedGame
                                |> mkCmd

                        else if key == "Backspace" then
                            RemoveTileBackspace game sharedGame
                                |> mkCmd

                        else
                            let
                                characterCmd =
                                    case toLetter key of
                                        Just k ->
                                            KeyCharPressed game sharedGame k
                                                |> mkCmd

                                        Nothing ->
                                            Cmd.none
                            in
                            characterCmd

                    else
                        Cmd.none
            in
            ( model, cmd )

        KeyCharPressed game sharedGame char ->
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
                        Started { game | selectedTiles = updatedSelectedTiles, availableTiles = updatedAvailableTiles } sharedGame

                    else
                        Started game sharedGame
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

        RemoveTileBackspace game sharedGame ->
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
                        Started { game | availableTiles = updatedAvailableTiles, selectedTiles = updatedSelectedTiles } sharedGame

                    else
                        Started game sharedGame
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

        GetConsonant game ->
            ( model, encodeListTiles game.availableTiles |> getRandomConsonant )

        GetVowel game ->
            ( model, encodeListTiles game.availableTiles |> getRandomVowel )

        GetRandom ->
            ( model, getRandomTiles () )

        ShuffleTiles game ->
            ( model, encodeListTiles game.availableTiles |> shuffleTiles )

        ReceiveRandomTiles game sharedGame tiles ->
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
                                            sharedGame

                                    else
                                        Started { game | availableTiles = tilesResult } sharedGame
                            in
                            newGameState

                        Err _ ->
                            Started game sharedGame
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

        ReceiveShuffledTiles game sharedGame tiles ->
            let
                updatedGameState =
                    case tiles of
                        Ok tilesResult ->
                            Started { game | availableTiles = tilesResult } sharedGame

                        Err _ ->
                            Started game sharedGame
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

        SelectTile game sharedGame selectedIdx tile ->
            let
                updatedSelectedTiles =
                    List.append game.selectedTiles [ tile ]

                updatedAvailableTiles =
                    LE.setAt selectedIdx { tile | hidden = True } game.availableTiles

                updatedGameState =
                    Started { game | selectedTiles = updatedSelectedTiles, availableTiles = updatedAvailableTiles } sharedGame
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

        RemoveTile game sharedGame originalIndex selectedIdx ->
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
                    Started { game | selectedTiles = updatedSelectedTiles, availableTiles = updatedAvailableTiles } sharedGame
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

        Submit game sharedGame ->
            let
                updatedGameState =
                    Started { game | isSubmitted = True } sharedGame
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

        SocketConnect info ->
            ( { model | socketInfo = SocketConnected info }, Cmd.none )

        Msg.SocketClosed code reason ->
            ( { model
                | socketInfo = WebSocket.SocketClosed code reason
                , gameState = NotStarted (Maybe.withDefault "No connection to server..." reason)
              }
            , Cmd.none
            )

        ReceivedString eventObject ->
            let
                sds =
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
                                Multiplayer.PlayerFound opponentId ->
                                    { model | gameState = Started initGame (Just (initSharedGame opponentId)) }

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
            ( { model | gameState = Searching }
            , WebSocket.sendJsonString
                (getConnectionInfo model.socketInfo)
                (WebSocket.searchingEncoder model.playerId)
            )
