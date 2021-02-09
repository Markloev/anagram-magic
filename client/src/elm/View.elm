module View exposing (view)

import Constants exposing (tileListMax)
import Game exposing (Game, GameState(..), Phase(..), SharedGame, SpecificRound(..), Tile)
import Helper exposing (getScore, hasMaxConsonants, hasMaxVowels, repeatHtml, unshuffleFinalWord)
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, classList, disabled, style)
import Html.Events exposing (onClick)
import List
import Msg exposing (Msg(..))
import Styles
import Svg exposing (circle, svg)
import Svg.Attributes exposing (cx, cy, r)
import Time
import Types exposing (Model)


view : Model -> Html Msg
view model =
    let
        content =
            case model.game.gameState of
                NotStarted ->
                    [ div [ class "flex justify-center" ] [ Styles.styledButton StartSearch "Start Search" Nothing ] ]

                Searching ->
                    [ div [ class "flex justify-center" ] [ Styles.styledButton StopSearch "Stop Search" Nothing ] ]

                Started sharedGame ->
                    gameView model.game sharedGame
    in
    div [ class "flex h-screen justify-center items-center" ]
        [ div [ style "width" "725px", class "justify-center p-4 rounded-md border-2 border-blue-400 bg-blue-100" ]
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

                Round _ ->
                    round game sharedGame

                CompletedRound currentRound ->
                    case currentRound of
                        FinalRound ->
                            finalRoundResults game sharedGame

                        _ ->
                            completedRound game sharedGame

                CompletedGame ->
                    completed game sharedGame
    in
    [ overview game sharedGame
    , gameContent
    ]


overview : Game -> SharedGame -> Html Msg
overview game sharedGame =
    div [ class "flex justify-between mb-4" ]
        [ div [ class "w-42 text-lg font-medium" ]
            [ text <| "Your Score: " ++ String.fromInt game.totalScore ]
        , div
            [ class "w-48 text-center" ]
            [ countdownTimer game
            ]
        , div [ class "flex w-42 text-lg font-medium justify-end" ]
            [ text <| "Opponent Score: " ++ String.fromInt sharedGame.totalScore ]
        ]


waiting : Html Msg
waiting =
    div [ class "flex w-full justify-center text-xl font-semibold overflow-hidden" ]
        [ text "Waiting on opponent..." ]


tileSelection : Game -> Html Msg
tileSelection game =
    let
        getConsonantsButton =
            if List.length game.availableTiles >= tileListMax || hasMaxConsonants game.availableTiles then
                Styles.styledButton NoOp "Consonant" (Just "w-24")

            else
                Styles.styledButton GetConsonant "Consonant" (Just "w-24")

        getVowelsButton =
            if List.length game.availableTiles >= tileListMax || hasMaxVowels game.availableTiles then
                Styles.styledButton NoOp "Vowel" (Just "w-24")

            else
                Styles.styledButton GetVowel "Vowel" (Just "w-24")
    in
    div [ class "flex flex-wrap overflow-hidden" ]
        [ div [ class "flex justify-center space-x-4 w-full overflow-hidden" ]
            [ getConsonantsButton
            , getVowelsButton
            ]
        , div [ class "w-full overflow-hidden" ]
            [ availableTiles game ]
        , div [ class "flex w-full justify-center overflow-hidden" ]
            [ Styles.styledButton GetRandom "9 Random Letters" Nothing ]
        ]


round : Game -> SharedGame -> Html Msg
round game sharedGame =
    let
        content =
            if game.waitingForUser then
                [ div [ class "flex w-full justify-center overflow-hidden space-x-4" ]
                    [ selectedTiles game
                    , Styles.styledDisabledButton "Backspace" (Just "w-24")
                    ]
                , div [ class "flex w-full justify-center overflow-hidden space-x-4" ]
                    [ availableTiles game
                    , Styles.styledDisabledButton "Shuffle" (Just "w-24")
                    ]
                , div [ class "flex w-full justify-center overflow-hidden" ]
                    [ Styles.styledDisabledButton "Submit" (Just "w-24")
                    ]
                ]

            else
                [ div [ class "flex w-full justify-center overflow-hidden space-x-4" ]
                    [ selectedTiles game
                    , Styles.styledButton RemoveTileBackspace "Backspace" (Just "w-24")
                    ]
                , div [ class "flex w-full justify-center overflow-hidden space-x-4" ]
                    [ availableTiles game
                    , Styles.styledButton ShuffleTiles "Shuffle" (Just "w-24")
                    ]
                , div [ class "flex w-full justify-center overflow-hidden" ]
                    [ Styles.styledButton (Submit sharedGame.phase) "Submit" (Just "w-24")
                    ]
                ]
    in
    div [ class "flex flex-wrap overflow-hidden" ]
        ([ div [ class "flex w-full h-6 min-h-full overflow-hidden" ]
            [ div [ class "flex flex-wrap w-full justify-start overflow-hidden space-x-1" ] <|
                repeatHtml (List.length game.selectedTiles) Styles.skeletonSelectedTile
            , div [ class "flex flex-wrap w-full justify-end overflow-hidden space-x-1" ] <|
                repeatHtml (List.length sharedGame.selectedTiles) Styles.skeletonSelectedTile
            ]
         , div [ class "flex w-full h-6 min-h-full overflow-hidden" ]
            [ div [ class "flex flex-wrap w-full justify-start font-medium overflow-hidden space-x-1" ] <|
                if game.waitingForUser then
                    [ text "Submitted!" ]

                else
                    [ text "" ]
            , div [ class "flex flex-wrap w-full justify-end font-medium overflow-hidden space-x-1" ] <|
                if sharedGame.waitingForUser then
                    [ text "Submitted!" ]

                else
                    [ text "" ]
            ]
         ]
            ++ content
        )


completedRound : Game -> SharedGame -> Html Msg
completedRound game sharedGame =
    div [ class "flex flex-wrap overflow-hidden" ]
        [ div [ class "flex w-full overflow-hidden" ]
            [ div [ class "flex flex-wrap w-full justify-start text-lg font-medium overflow-hidden space-x-1" ]
                [ text <| "Points: " ++ (String.fromInt <| getScore game.validWord game.selectedTiles) ]
            , div [ class "flex flex-wrap w-full justify-end text-lg font-medium overflow-hidden space-x-1" ]
                [ text <| "Points: " ++ (String.fromInt <| getScore sharedGame.validWord sharedGame.selectedTiles) ]
            ]
        , div [ class "flex w-full overflow-hidden" ]
            [ if game.waitingForUser then
                div [ class "flex w-full justify-center text-xl font-semibold overflow-hidden" ]
                    [ text "Waiting on opponent..." ]

              else
                div [] []
            ]
        , div [ class "flex w-full overflow-hidden" ]
            [ div [ class "flex flex-wrap w-full justify-start overflow-hidden space-x-1" ]
                [ resultsSelectedTiles game.selectedTiles ]
            , div [ class "flex flex-wrap w-full justify-end overflow-hidden space-x-1" ]
                [ resultsSelectedTiles sharedGame.selectedTiles ]
            ]
        , div [ class "flex w-full justify-center overflow-hidden" ]
            [ if game.waitingForUser then
                Styles.styledDisabledButton "Next Round" (Just "w-32")

              else
                Styles.styledButton (NextRound sharedGame.phase) "Next Round" (Just "w-32")
            ]
        ]


finalRoundResults : Game -> SharedGame -> Html Msg
finalRoundResults game sharedGame =
    div [ class "flex flex-wrap overflow-hidden" ]
        [ div [ class "flex w-full overflow-hidden" ]
            [ div [ class "flex flex-wrap w-full justify-start text-lg font-medium overflow-hidden space-x-1" ]
                [ text <| "Points: " ++ (String.fromInt <| getScore game.validWord game.selectedTiles) ]
            , div [ class "flex flex-wrap w-full justify-end text-lg font-medium overflow-hidden space-x-1" ]
                [ text <| "Points: " ++ (String.fromInt <| getScore sharedGame.validWord sharedGame.selectedTiles) ]
            ]
        , div [ class "flex w-full overflow-hidden" ]
            [ div [ class "flex w-full justify-center overflow-hidden" ]
                [ game.availableTiles
                    |> unshuffleFinalWord
                    |> resultsSelectedTiles
                ]
            ]
        , div [ class "flex w-full justify-center overflow-hidden" ]
            [ Styles.styledButton Continue "Continue" (Just "w-32")
            ]
        ]


completed : Game -> SharedGame -> Html Msg
completed game sharedGame =
    let
        victoryText =
            if game.totalScore > sharedGame.totalScore then
                "You Won!"

            else if game.totalScore < sharedGame.totalScore then
                "You Lost!"

            else
                "You Tied!"
    in
    div [ class "flex flex-wrap overflow-hidden" ]
        [ div [ class "flex w-full justify-center text-3xl font-bold overflow-hidden" ]
            [ text victoryText ]
        , div [ class "flex w-full justify-center overflow-hidden" ]
            [ Styles.styledButton EndGame "End Game" (Just "w-32")
            ]
        ]


availableTiles : Game -> Html Msg
availableTiles game =
    let
        tileContent =
            List.indexedMap
                (\idx tile ->
                    if tile.hidden then
                        Styles.skeletonTile

                    else if game.waitingForUser then
                        Styles.styledTile NoOp tile Nothing

                    else
                        Styles.styledTile (SelectTile idx tile) tile Nothing
                )
                game.availableTiles
    in
    div [ class "flex flex-wrap space-x-2" ] <| tileContent


selectedTiles : Game -> Html Msg
selectedTiles game =
    let
        tileContent =
            List.indexedMap
                (\idx tile ->
                    if game.waitingForUser then
                        Styles.styledTile NoOp tile Nothing

                    else
                        Styles.styledTile (RemoveTile tile.originalIndex idx) tile Nothing
                )
                game.selectedTiles

        skeletonTiles =
            repeatHtml (9 - List.length game.selectedTiles) Styles.skeletonTile
    in
    div [ class "flex flex-wrap justify-start space-x-2 overflow-hidden" ] <| tileContent ++ skeletonTiles


resultsSelectedTiles : List Tile -> Html Msg
resultsSelectedTiles tiles =
    let
        tileContent =
            List.map
                (\tile ->
                    Styles.styledTile NoOp tile (Just "w-8, h-8")
                )
                tiles
    in
    div [ class "flex flex-wrap justify-start space-x-2 overflow-hidden" ] <| tileContent


countdownTimer : Game -> Html Msg
countdownTimer game =
    div [ class "countdown" ]
        [ div [ class "countdown-number font-medium" ]
            [ text <|
                String.fromInt
                    (game.timeInterval
                        - (Time.posixToMillis game.currentTime
                            - Time.posixToMillis game.startedTime
                            |> Time.millisToPosix
                            |> Time.toSecond Time.utc
                          )
                    )
            ]
        , svg []
            [ circle
                [ r "18"
                , cx "20"
                , cy "20"
                , style "animation" ("countdown " ++ String.fromInt game.timeInterval ++ "s linear infinite forwards")
                ]
                []
            ]
        ]
