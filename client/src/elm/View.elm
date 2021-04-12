module View exposing (view)

import Constants exposing (tileListMax)
import Game exposing (Game, GameState(..), Phase(..), SpecificRound(..), Tile)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Html.Extra as HE
import List
import Model exposing (Model)
import Msg exposing (Msg(..))
import Utils.CoreHelpers exposing (getScore)
import Utils.ViewHelpers exposing (hasMaxConsonants, hasMaxVowels, repeatHtml, skeletonSelectedTile, skeletonTile, styledButton, styledDisabledButton, styledTile, unshuffleFinalWord)


view : Model -> Html Msg
view model =
    let
        content =
            case model.gameState of
                NotStarted ->
                    [ div [ class "flex justify-center" ] [ styledButton StartSearch "Start Search" Nothing ] ]

                Searching ->
                    [ div [ class "flex justify-center" ] [ styledButton StopSearch "Stop Search" Nothing ] ]

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
        , div [ class "flex w-44 text-lg font-medium justify-end items-center" ]
            [ text <| "Opponent Score: " ++ String.fromInt game.shared.totalScore ]
        ]


waiting : Html Msg
waiting =
    div [ class "flex w-full justify-center text-xl font-semibold" ]
        [ text "Waiting on opponent..." ]


tileSelection : Game -> Html Msg
tileSelection game =
    let
        getConsonantsButton =
            if List.length game.availableTiles >= tileListMax || hasMaxConsonants game.availableTiles then
                styledDisabledButton "Consonant" (Just "w-24")

            else
                styledButton (GetConsonant game) "Consonant" (Just "w-24")

        getVowelsButton =
            if List.length game.availableTiles >= tileListMax || hasMaxVowels game.availableTiles then
                styledDisabledButton "Vowel" (Just "w-24")

            else
                styledButton (GetVowel game) "Vowel" (Just "w-24")
    in
    div [ class "flex flex-wrap" ]
        [ div [ class "flex justify-center space-x-4 w-full" ]
            [ getConsonantsButton
            , getVowelsButton
            ]
        , div [ class "w-full" ]
            [ availableTiles game ]
        , div [ class "flex w-full justify-center" ]
            [ styledButton GetRandom "9 Random Letters" Nothing ]
        ]


round : Game -> Html Msg
round game =
    let
        content =
            if game.waitingForUser then
                [ div [ class "flex w-full justify-center space-x-4" ]
                    [ selectedTiles game
                    , styledDisabledButton "Backspace" (Just "w-24")
                    ]
                , div [ class "flex w-full justify-center space-x-4" ]
                    [ availableTiles game
                    , styledDisabledButton "Shuffle" (Just "w-24")
                    ]
                , div [ class "flex w-full justify-center" ]
                    [ styledDisabledButton "Submit" (Just "w-24")
                    ]
                ]

            else
                [ div [ class "flex w-full justify-center space-x-4" ]
                    [ selectedTiles game
                    , styledButton (RemoveTileBackspace game) "Backspace" (Just "w-24")
                    ]
                , div [ class "flex w-full justify-center space-x-4" ]
                    [ availableTiles game
                    , styledButton (ShuffleTiles game) "Shuffle" (Just "w-24")
                    ]
                , div [ class "flex w-full justify-center" ]
                    [ styledButton (Submit game) "Submit" (Just "w-24")
                    ]
                ]
    in
    div [ class "flex flex-wrap" ]
        ([ div [ class "flex w-full h-6 min-h-full" ]
            [ div [ class "flex flex-wrap w-full justify-start space-x-1" ] <|
                repeatHtml (List.length game.selectedTiles) skeletonSelectedTile
            , div [ class "flex flex-wrap w-full justify-end space-x-1" ] <|
                repeatHtml (List.length game.shared.selectedTiles) skeletonSelectedTile
            ]
         , div [ class "flex w-full h-6 min-h-full" ]
            [ div [ class "flex flex-wrap w-full justify-start font-medium space-x-1" ] <|
                if game.waitingForUser then
                    [ text "Submitted!" ]

                else
                    [ text "" ]
            , div [ class "flex flex-wrap w-full justify-end font-medium space-x-1" ] <|
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
    div [ class "flex flex-wrap" ]
        [ div [ class "flex w-full" ]
            [ div [ class "flex flex-wrap w-full justify-start text-lg font-medium space-x-1" ]
                [ text <| "Points: " ++ (String.fromInt <| getScore game.validWord game.selectedTiles) ]
            , div [ class "flex flex-wrap w-full justify-end text-lg font-medium space-x-1" ]
                [ text <| "Points: " ++ (String.fromInt <| getScore game.shared.validWord game.shared.selectedTiles) ]
            ]
        , div [ class "flex w-full" ]
            [ if game.waitingForUser then
                div [ class "flex w-full justify-center text-xl font-semibold" ]
                    [ text "Waiting on opponent..." ]

              else
                HE.nothing
            ]
        , div [ class "flex w-full" ]
            [ div [ class "flex flex-wrap w-full justify-start space-x-1" ]
                [ resultsSelectedTiles game.selectedTiles ]
            , div [ class "flex flex-wrap w-full justify-end space-x-1" ]
                [ resultsSelectedTiles game.shared.selectedTiles ]
            ]
        , div [ class "flex w-full justify-center" ]
            [ if game.waitingForUser then
                styledDisabledButton "Next Round" (Just "w-32")

              else
                styledButton (NextRound game) "Next Round" (Just "w-32")
            ]
        ]


finalRoundResults : Game -> Html Msg
finalRoundResults game =
    div [ class "flex flex-wrap" ]
        [ div [ class "flex w-full" ]
            [ div [ class "flex flex-wrap w-full justify-start text-lg font-medium space-x-1" ]
                [ text <| "Points: " ++ (String.fromInt <| getScore game.validWord game.selectedTiles) ]
            , div [ class "flex flex-wrap w-full justify-end text-lg font-medium space-x-1" ]
                [ text <| "Points: " ++ (String.fromInt <| getScore game.shared.validWord game.shared.selectedTiles) ]
            ]
        , div [ class "flex w-full" ]
            [ div [ class "flex w-full justify-center" ]
                [ game.availableTiles
                    |> unshuffleFinalWord
                    |> resultsSelectedTiles
                ]
            ]
        , div [ class "flex w-full justify-center" ]
            [ styledButton (Continue game) "Continue" (Just "w-32")
            ]
        ]


completed : Game -> Html Msg
completed game =
    let
        gameOver =
            if not game.errorOccurred then
                if game.totalScore > game.shared.totalScore then
                    div [ class "flex w-full justify-center text-3xl font-bold" ] [ text "You Won!" ]

                else if game.totalScore < game.shared.totalScore then
                    div [ class "flex w-full justify-center text-3xl font-bold" ] [ text "You Lost!" ]

                else
                    div [ class "flex w-full justify-center text-3xl font-bold" ] [ text "You Tied!" ]

            else
                div [ class "flex w-full flex-wrap font-bold" ]
                    [ div [ class "flex w-full justify-center text-xl" ] [ text "Something went wrong with your opponent's game..." ]
                    , div [ class "flex w-full justify-center text-3xl" ] [ text "You won!" ]
                    ]
    in
    div [ class "flex flex-wrap" ]
        [ gameOver
        , div [ class "flex w-full justify-center" ]
            [ styledButton EndGame "End Game" (Just "w-32")
            ]
        ]


availableTiles : Game -> Html Msg
availableTiles game =
    let
        tileContent =
            List.indexedMap
                (\idx tile ->
                    if tile.hidden then
                        skeletonTile

                    else if game.waitingForUser then
                        styledTile tile (class "") Nothing

                    else
                        styledTile tile (onClick <| SelectTile game idx tile) Nothing
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
                        styledTile tile (class "") Nothing

                    else
                        styledTile tile (onClick <| RemoveTile game tile.originalIndex idx) Nothing
                )
                game.selectedTiles

        skeletonTiles =
            repeatHtml (9 - List.length game.selectedTiles) skeletonTile
    in
    div [ class "flex flex-wrap justify-start space-x-2" ] <| tileContent ++ skeletonTiles


resultsSelectedTiles : List Tile -> Html Msg
resultsSelectedTiles tiles =
    let
        tileContent =
            List.map
                (\tile ->
                    styledTile tile (class "") (Just "w-8, h-8")
                )
                tiles
    in
    div [ class "flex flex-wrap justify-start space-x-2" ] <| tileContent
