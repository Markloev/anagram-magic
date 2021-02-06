module View exposing (view)

import Constants exposing (tileListMax)
import Game exposing (Game, GameState(..), Phase(..), SharedGame, SpecificRound(..))
import Helper exposing (hasMaxConsonants, hasMaxVowels)
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, classList, disabled, style)
import Html.Events exposing (onClick)
import List
import Msg exposing (Msg(..))
import Styles
import Time
import Types exposing (Model)


view : Model -> Html Msg
view model =
    let
        content =
            case model.game.gameState of
                NotStarted ->
                    [ Styles.styledButton StartSearch "Start Search" Nothing ]

                Searching ->
                    [ Styles.styledButton StopSearch "Stop Search" Nothing ]

                Started sharedGame ->
                    gameView model.game sharedGame
    in
    div [ class "flex h-screen justify-center items-center" ]
        [ div [ class "p-12 rounded-md border-2 border-blue-400" ]
            content
        ]


gameView : Game -> SharedGame -> List (Html Msg)
gameView game sharedGame =
    let
        gameContent =
            case sharedGame.phase of
                Waiting _ ->
                    waiting

                TileSelection _ ->
                    tileSelection game

                Round round ->
                    case round of
                        FinalRound ->
                            finalRound game

                        _ ->
                            regularRound game sharedGame

                CompletedRound round ->
                    case round of
                        FinalRound ->
                            finalRoundResults game sharedGame

                        _ ->
                            regularRoundResults game sharedGame

                CompletedGame ->
                    completed game
    in
    [ overview game
    , gameContent
    , div [] [ text <| "PLAYER 2: " ++ sharedGame.playerId ]
    ]


overview : Game -> Html Msg
overview game =
    div [] [ text <| String.fromInt <| Time.toSecond Time.utc (Time.millisToPosix (Time.posixToMillis game.currentTime - Time.posixToMillis game.startedTime)) ]


waiting : Html Msg
waiting =
    div [] [ text "Waiting" ]


tileSelection : Game -> Html Msg
tileSelection game =
    let
        getConsonantsButton =
            if List.length game.availableTiles >= tileListMax || hasMaxConsonants game.availableTiles then
                Styles.styledButton DoNothing "Consonant" Nothing

            else
                Styles.styledButton GetConsonant "Consonant" Nothing

        getVowelsButton =
            if List.length game.availableTiles >= tileListMax || hasMaxVowels game.availableTiles then
                Styles.styledButton DoNothing "Vowel" Nothing

            else
                Styles.styledButton GetVowel "Vowel" Nothing
    in
    div [ class "flex flex-wrap overflow-hidden xl:-mx-2" ]
        [ div [ class "w-full overflow-hidden xl:my-2 xl:px-2 xl:w-1/2" ]
            [ getConsonantsButton ]
        , div [ class "w-full overflow-hidden xl:my-2 xl:px-2 xl:w-1/2" ]
            [ getVowelsButton ]
        , div [ class "w-full overflow-hidden xl:my-2 xl:px-2 xl:w-1/2" ]
            [ availableTiles game ]
        , div [ class "w-full overflow-hidden xl:my-2 xl:px-2 xl:w-1/2" ]
            [ Styles.styledButton GetRandom "9 Random Letters" Nothing ]
        ]


regularRound : Game -> SharedGame -> Html Msg
regularRound game sharedGame =
    div [ class "flex" ]
        [ Styles.styledButton ShuffleTiles "Shuffle" Nothing
        , availableTiles game
        , selectedTiles game
        , opponentSelectedTiles sharedGame
        , Styles.styledButton Submit "Submit" Nothing
        ]


finalRound : Game -> Html Msg
finalRound _ =
    div [] [ text "Final Round" ]


completed : Game -> Html Msg
completed _ =
    div [] [ text "Completed Game" ]


regularRoundResults : Game -> SharedGame -> Html Msg
regularRoundResults game sharedGame =
    div []
        [ div [] [ text <| "Your score: " ++ String.fromInt game.totalScore ]
        , div [] [ text <| "Opponent score: " ++ String.fromInt sharedGame.totalScore ]
        , Styles.styledButton (NextRound sharedGame.phase) "Next Round" Nothing
        ]


finalRoundResults : Game -> SharedGame -> Html Msg
finalRoundResults game sharedGame =
    div [] [ text "Final Round Results" ]


availableTiles : Game -> Html Msg
availableTiles game =
    let
        tileContent =
            List.indexedMap
                (\idx tile ->
                    if tile.hidden then
                        div [] [ text "Hidden" ]

                    else
                        div []
                            [ Styles.styledButton (SelectTile idx tile) (String.fromChar tile.letter ++ " / " ++ String.fromInt tile.value) (Just Styles.tileClasses)
                            ]
                )
                game.availableTiles
    in
    div [] <| tileContent


selectedTiles : Game -> Html Msg
selectedTiles game =
    let
        tileContent =
            List.indexedMap
                (\idx tile ->
                    div []
                        [ Styles.styledButton (RemoveTile tile.originalIndex idx) (String.fromChar tile.letter ++ " / " ++ String.fromInt tile.value) (Just Styles.tileClasses)
                        ]
                )
                game.selectedTiles
    in
    div [] <| tileContent


opponentSelectedTiles : SharedGame -> Html Msg
opponentSelectedTiles sharedGame =
    let
        tileContent =
            List.map
                (\tile ->
                    div []
                        [ text <| String.fromChar tile.letter ++ " / " ++ String.fromInt tile.value ]
                )
                sharedGame.selectedTiles
    in
    div [] <| tileContent
