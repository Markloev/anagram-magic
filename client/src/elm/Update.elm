module Update exposing (update)

import Browser.Dom as Dom
import Game exposing (GameState(..), Phase(..), initGame)
import Helper exposing (consonants, mkCmd, toLetter, vowels)
import List
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
                                    case g.phase of
                                        TileSelection ->
                                            let
                                                sddsds =
                                                    Debug.log "here" (Time.toSecond Time.utc g.startTime)

                                                sdsd =
                                                    Debug.log "sss" (iff isStart posix g.startTime)

                                                finalGameState =
                                                    if Time.toSecond Time.utc g.startTime == 10 then
                                                        { g
                                                            | phase =
                                                                if g.round < 5 then
                                                                    RegularRound

                                                                else
                                                                    FinalRound
                                                            , startTime = posix
                                                        }

                                                    else
                                                        { g | startTime = iff isStart g.startTime posix }
                                            in
                                            finalGameState

                                        _ ->
                                            let
                                                newRound =
                                                    g.round + 1

                                                finalGameState =
                                                    if Time.toSecond Time.utc g.startTime == 30 then
                                                        { g
                                                            | round = newRound
                                                            , phase =
                                                                if newRound < 5 then
                                                                    TileSelection

                                                                else
                                                                    Completed
                                                            , startTime = posix
                                                        }

                                                    else
                                                        { g | startTime = iff isStart posix g.startTime }
                                            in
                                            finalGameState
                            in
                            Started newGameState
            in
            ( { model | gameState = updatedGameState }, Cmd.none )

        KeyPressed gameState key ->
            let
                cmd =
                    case gameState of
                        Started game ->
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

                        NotStarted ->
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
                                        ( List.append game.selectedTiles [ t ], LE.setAt t.originalIndex { t | hidden = True } game.availableTiles )

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
                                                        , isSubmitted = False
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
            ( { model | gameState = updatedGameState }, Cmd.none )
