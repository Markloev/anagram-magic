module View exposing (view)

import Constants exposing (tileListMax)
import Game exposing (Game, GameState(..), Phase(..), SpecificRound(..), Tile)
import Helper exposing (getScore, hasMaxConsonants, hasMaxVowels, repeatHtml, unshuffleFinalWord)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
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
            case model.gameState of
                NotStarted ->
                    [ div [ class "flex justify-center" ] [ Styles.styledButton StartSearch "Start Search" Nothing ] ]

                Searching ->
                    [ div [ class "flex justify-center" ] [ Styles.styledButton StopSearch "Stop Search" Nothing ] ]

                Started game ->
                    gameView game
    in
    div [ class "flex h-screen justify-center items-center" ]
        [ div [ style "width" "725px", class "justify-center p-4 rounded-md border-2 border-blue-400 bg-blue-100" ]
            content
        ]


gameView : Game -> List (Html Msg)
gameView game =
    let
        gameContent =
            case game.phase of
                Waiting _ ->
                    waiting

                TileSelection _ ->
                    tileSelection game

                Round _ ->
                    round game

                CompletedRound currentRound ->
                    case currentRound of
                        FinalRound ->
                            finalRoundResults game

                        _ ->
                            completedRound game

                CompletedGame ->
                    completed game
    in
    [ overview game
    , gameContent
    ]


overview : Game -> Html Msg
overview game =
    div [ class "flex justify-between mb-4" ]
        [ div [ class "flex w-44 text-lg font-medium justify-start items-center" ]
            [ text <| "Your Score: " ++ String.fromInt game.totalScore ]
        , div
            [ class "w-48 text-center" ]
          <|
            case game.phase of
                CompletedGame ->
                    []

                _ ->
                    [ if game.time.paused then
                        div [] []

                      else
                        countdownTimer game
                    ]
        , div [ class "flex w-44 text-lg font-medium justify-end items-center" ]
            [ text <| "Opponent Score: " ++ String.fromInt game.shared.totalScore ]
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
                Styles.styledDisabledButton "Consonant" (Just "w-24")

            else
                Styles.styledButton (GetConsonant game) "Consonant" (Just "w-24")

        getVowelsButton =
            if List.length game.availableTiles >= tileListMax || hasMaxVowels game.availableTiles then
                Styles.styledDisabledButton "Vowel" (Just "w-24")

            else
                Styles.styledButton (GetVowel game) "Vowel" (Just "w-24")
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


round : Game -> Html Msg
round game =
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
                    , Styles.styledButton (RemoveTileBackspace game) "Backspace" (Just "w-24")
                    ]
                , div [ class "flex w-full justify-center overflow-hidden space-x-4" ]
                    [ availableTiles game
                    , Styles.styledButton (ShuffleTiles game) "Shuffle" (Just "w-24")
                    ]
                , div [ class "flex w-full justify-center overflow-hidden" ]
                    [ Styles.styledButton (Submit game) "Submit" (Just "w-24")
                    ]
                ]
    in
    div [ class "flex flex-wrap overflow-hidden" ]
        ([ div [ class "flex w-full h-6 min-h-full overflow-hidden" ]
            [ div [ class "flex flex-wrap w-full justify-start overflow-hidden space-x-1" ] <|
                repeatHtml (List.length game.selectedTiles) Styles.skeletonSelectedTile
            , div [ class "flex flex-wrap w-full justify-end overflow-hidden space-x-1" ] <|
                repeatHtml (List.length game.shared.selectedTiles) Styles.skeletonSelectedTile
            ]
         , div [ class "flex w-full h-6 min-h-full overflow-hidden" ]
            [ div [ class "flex flex-wrap w-full justify-start font-medium overflow-hidden space-x-1" ] <|
                if game.waitingForUser then
                    [ text "Submitted!" ]

                else
                    [ text "" ]
            , div [ class "flex flex-wrap w-full justify-end font-medium overflow-hidden space-x-1" ] <|
                if game.shared.waitingForUser then
                    [ text "Submitted!" ]

                else
                    [ text "" ]
            ]
         ]
            ++ content
        )


completedRound : Game -> Html Msg
completedRound game =
    div [ class "flex flex-wrap overflow-hidden" ]
        [ div [ class "flex w-full overflow-hidden" ]
            [ div [ class "flex flex-wrap w-full justify-start text-lg font-medium overflow-hidden space-x-1" ]
                [ text <| "Points: " ++ (String.fromInt <| getScore game.validWord game.selectedTiles) ]
            , div [ class "flex flex-wrap w-full justify-end text-lg font-medium overflow-hidden space-x-1" ]
                [ text <| "Points: " ++ (String.fromInt <| getScore game.shared.validWord game.shared.selectedTiles) ]
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
                [ resultsSelectedTiles game.shared.selectedTiles ]
            ]
        , div [ class "flex w-full justify-center overflow-hidden" ]
            [ if game.waitingForUser then
                Styles.styledDisabledButton "Next Round" (Just "w-32")

              else
                Styles.styledButton (NextRound game) "Next Round" (Just "w-32")
            ]
        ]


finalRoundResults : Game -> Html Msg
finalRoundResults game =
    div [ class "flex flex-wrap overflow-hidden" ]
        [ div [ class "flex w-full overflow-hidden" ]
            [ div [ class "flex flex-wrap w-full justify-start text-lg font-medium overflow-hidden space-x-1" ]
                [ text <| "Points: " ++ (String.fromInt <| getScore game.validWord game.selectedTiles) ]
            , div [ class "flex flex-wrap w-full justify-end text-lg font-medium overflow-hidden space-x-1" ]
                [ text <| "Points: " ++ (String.fromInt <| getScore game.shared.validWord game.shared.selectedTiles) ]
            ]
        , div [ class "flex w-full overflow-hidden" ]
            [ div [ class "flex w-full justify-center overflow-hidden" ]
                [ game.availableTiles
                    |> unshuffleFinalWord
                    |> resultsSelectedTiles
                ]
            ]
        , div [ class "flex w-full justify-center overflow-hidden" ]
            [ Styles.styledButton (Continue game) "Continue" (Just "w-32")
            ]
        ]


completed : Game -> Html Msg
completed game =
    let
        gameOver =
            if not game.errorOccurred then
                if game.totalScore > game.shared.totalScore then
                    div [ class "flex w-full justify-center text-3xl font-bold overflow-hidden" ] [ text "You Won!" ]

                else if game.totalScore < game.shared.totalScore then
                    div [ class "flex w-full justify-center text-3xl font-bold overflow-hidden" ] [ text "You Lost!" ]

                else
                    div [ class "flex w-full justify-center text-3xl font-bold overflow-hidden" ] [ text "You Tied!" ]

            else
                div [ class "flex w-full flex-wrap font-bold overflow-hidden" ]
                    [ div [ class "flex w-full justify-center text-xl overflow-hidden" ] [ text "Something went wrong with your opponent's game..." ]
                    , div [ class "flex w-full justify-center text-3xl overflow-hidden" ] [ text "You won!" ]
                    ]
    in
    div [ class "flex flex-wrap overflow-hidden" ]
        [ gameOver
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
                        Styles.styledTile tile (class "") Nothing

                    else
                        Styles.styledTile tile (onClick <| SelectTile game idx tile) Nothing
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
                        Styles.styledTile tile (class "") Nothing

                    else
                        Styles.styledTile tile (onClick <| RemoveTile game tile.originalIndex idx) Nothing
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
                    Styles.styledTile tile (class "") (Just "w-8, h-8")
                )
                tiles
    in
    div [ class "flex flex-wrap justify-start space-x-2 overflow-hidden" ] <| tileContent


countdownTimer : Game -> Html Msg
countdownTimer game =
    div [ class "countdown" ]
        [ div [ class "countdown-number font-medium" ]
            [ text <|
                if game.time.paused then
                    "0"

                else
                    String.fromInt
                        (game.time.timeInterval
                            - (Time.posixToMillis game.time.currentTime
                                - Time.posixToMillis game.time.startedTime
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
                , if game.time.paused then
                    class ""

                  else
                    style "animation" ("countdown " ++ String.fromInt game.time.timeInterval ++ "s linear infinite forwards")
                ]
                []
            ]
        ]
