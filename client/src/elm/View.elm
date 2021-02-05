module View exposing (view)

import Constants exposing (tileListMax)
import Game exposing (Game, GameState(..), Phase(..), SharedGame, SpecificRound(..))
import Helper exposing (hasMaxConsonants, hasMaxVowels)
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, classList, disabled, style)
import Html.Events exposing (onClick)
import List
import Msg exposing (Msg(..))
import Time
import Types exposing (Model)


view : Model -> Html Msg
view model =
    let
        content =
            case model.game.gameState of
                NotStarted ->
                    button [ onClick StartSearch, class "p-2 my-2 bg-blue-400 text-white rounded-md focus:outline-none focus:ring-2 ring-blue-200" ] [ text "Start Search" ]

                Searching ->
                    button [ onClick StopSearch, class "button" ] [ text "Stop Search" ]

                Started sharedGame ->
                    gameView model.game sharedGame
    in
    div [ style "height" "100%", style "width" "100%", class "content-container" ]
        [ content ]


gameView : Game -> SharedGame -> Html Msg
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
    div []
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
                button [ onClick GetConsonant, disabled True, class "button" ] [ text "Consonant" ]

            else
                button [ onClick GetConsonant, class "button" ] [ text "Consonant" ]

        getVowelsButton =
            if List.length game.availableTiles >= tileListMax || hasMaxVowels game.availableTiles then
                button [ onClick GetVowel, disabled True, class "button" ] [ text "Vowel" ]

            else
                button [ onClick GetVowel, class "button" ] [ text "Vowel" ]
    in
    div [ classList [ ( "flex", True ), ( "flex-col", True ) ] ]
        [ getConsonantsButton
        , getVowelsButton
        , button [ onClick GetRandom, class "button" ] [ text "9 Random Letters" ]
        , availableTiles game
        ]


regularRound : Game -> SharedGame -> Html Msg
regularRound game sharedGame =
    div [ classList [ ( "flex", True ), ( "flex-row", True ) ] ]
        [ button [ onClick ShuffleTiles, class "button" ] [ text "Shuffle" ]
        , availableTiles game
        , selectedTiles game
        , opponentSelectedTiles sharedGame
        , button [ onClick Submit, class "button" ] [ text "Submit" ]
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
        , button [ onClick NextRound, class "button" ] [ text "Next Round" ]
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
                            [ button [ onClick <| SelectTile idx tile, class "button" ] [ text <| String.fromChar tile.letter ++ " / " ++ String.fromInt tile.value ]
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
                        [ button [ onClick <| RemoveTile tile.originalIndex idx, class "button" ] [ text <| String.fromChar tile.letter ++ " / " ++ String.fromInt tile.value ]
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
