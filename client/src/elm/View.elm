module View exposing (view)

import Constants exposing (tileListMax)
import Game exposing (Game, GameState(..), Phase(..), SharedGame, SpecificRound(..), Tile)
import Helper exposing (getScore, hasMaxConsonants, hasMaxVowels, repeatHtml)
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
                    [ div [ class "flex justify-center" ] [ Styles.styledButton StartSearch "Start Search" Nothing ] ]

                Searching ->
                    [ div [ class "flex justify-center" ] [ Styles.styledButton StopSearch "Stop Search" Nothing ] ]

                Started sharedGame ->
                    gameView model.game sharedGame
    in
    div [ class "flex h-screen justify-center items-center" ]
        [ div [ style "width" "725px", class "justify-center p-12 rounded-md border-2 border-blue-400" ]
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
                            completedRound game sharedGame

                CompletedGame ->
                    completed game
    in
    [ overview game sharedGame
    , gameContent
    ]


overview : Game -> SharedGame -> Html Msg
overview game sharedGame =
    div [ class "flex justify-between" ]
        [ div [ class "w-36" ]
            [ text <| "Your Score: " ++ String.fromInt game.totalScore ]
        , div
            [ class "w-48 text-center" ]
            [ Time.posixToMillis game.currentTime
                - Time.posixToMillis game.startedTime
                |> Time.millisToPosix
                |> Time.toSecond Time.utc
                |> String.fromInt
                |> text
            ]
        , div [ class "flex w-36 justify-end" ]
            [ text <| "Opponent Score: " ++ String.fromInt sharedGame.totalScore ]
        ]


waiting : Html Msg
waiting =
    div [] [ text "Waiting" ]


tileSelection : Game -> Html Msg
tileSelection game =
    let
        getConsonantsButton =
            if List.length game.availableTiles >= tileListMax || hasMaxConsonants game.availableTiles then
                Styles.styledButton DoNothing "Consonant" (Just "w-24")

            else
                Styles.styledButton GetConsonant "Consonant" (Just "w-24")

        getVowelsButton =
            if List.length game.availableTiles >= tileListMax || hasMaxVowels game.availableTiles then
                Styles.styledButton DoNothing "Vowel" (Just "w-24")

            else
                Styles.styledButton GetVowel "Vowel" (Just "w-24")
    in
    div [ class "flex flex-wrap overflow-hidden xl:-mx-2" ]
        [ div [ class "flex justify-center space-x-4 w-full overflow-hidden xl:my-2 xl:px-2 xl:w-1/2" ]
            [ getConsonantsButton
            , getVowelsButton
            ]
        , div [ class "w-full overflow-hidden xl:my-2 xl:px-2 xl:w-1/2" ]
            [ availableTiles game ]
        , div [ class "w-full overflow-hidden" ]
            [ Styles.styledButton GetRandom "9 Random Letters" (Just "w-full") ]
        ]


regularRound : Game -> SharedGame -> Html Msg
regularRound game sharedGame =
    div [ class "flex flex-wrap overflow-hidden xl:-mx-2" ]
        [ div [ class "flex w-full h-6 min-h-full overflow-hidden" ]
            [ div [ class "flex flex-wrap w-full justify-start overflow-hidden space-x-1" ] <| repeatHtml (List.length game.selectedTiles) Styles.skeletonSelectedTile
            , div [ class "flex flex-wrap w-full justify-end overflow-hidden space-x-1" ] <| repeatHtml (List.length sharedGame.selectedTiles) Styles.skeletonSelectedTile
            ]
        , div [ class "flex w-full justify-end overflow-hidden space-x-4" ]
            [ selectedTiles game
            , Styles.styledButton RemoveTileBackspace "Backspace" (Just "w-24")
            ]
        , div [ class "flex w-full justify-end overflow-hidden space-x-4" ]
            [ availableTiles game
            , Styles.styledButton ShuffleTiles "Shuffle" (Just "w-24")
            ]
        , div [ class "flex w-full justify-center overflow-hidden" ]
            [ Styles.styledButton Submit "Submit" (Just "w-24")
            ]
        ]


completedRound : Game -> SharedGame -> Html Msg
completedRound game sharedGame =
    div [ class "flex flex-wrap overflow-hidden xl:-mx-2" ]
        [ div [ class "flex w-full overflow-hidden" ]
            [ div [ class "flex flex-wrap w-full justify-start overflow-hidden space-x-1" ]
                [ text <| "Points: " ++ (String.fromInt <| getScore game.selectedTiles) ]
            , div [ class "flex flex-wrap w-full justify-end overflow-hidden space-x-1" ]
                [ text <| "Points: " ++ (String.fromInt <| getScore sharedGame.selectedTiles) ]
            ]
        , div [ class "flex w-full overflow-hidden" ]
            [ div [ class "flex flex-wrap w-full justify-start overflow-hidden space-x-1" ]
                [ resultsSelectedTiles game.selectedTiles ]
            , div [ class "flex flex-wrap w-full justify-end overflow-hidden space-x-1" ]
                [ resultsSelectedTiles sharedGame.selectedTiles ]
            ]
        , div [ class "flex w-full justify-center overflow-hidden" ]
            [ Styles.styledButton (NextRound sharedGame.phase) "Next Round" (Just "w-32")
            ]
        ]


finalRound : Game -> Html Msg
finalRound _ =
    div [] [ text "Final Round" ]


completed : Game -> Html Msg
completed _ =
    div [] [ text "Completed Game" ]


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
                        Styles.skeletonTile

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
                    Styles.styledTile (RemoveTile tile.originalIndex idx) tile Nothing
                )
                game.selectedTiles

        skeletonTiles =
            repeatHtml (9 - List.length game.selectedTiles) Styles.skeletonTile
    in
    div [ class "flex flex-wrap justify-start space-x-2 overflow-hidden xl:-mx-2" ] <| tileContent ++ skeletonTiles


resultsSelectedTiles : List Tile -> Html Msg
resultsSelectedTiles tiles =
    let
        tileContent =
            List.map
                (\tile ->
                    Styles.styledTile DoNothing tile (Just "w-8, h-8")
                )
                tiles
    in
    div [ class "flex flex-wrap justify-start space-x-2 overflow-hidden xl:-mx-2" ] <| tileContent
