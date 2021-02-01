module View exposing (view)

import Constants exposing (tileListMax)
import Game exposing (Game, GameState(..), Phase(..), SharedGame)
import Helper exposing (hasMaxConsonants, hasMaxVowels)
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, classList, disabled, style, type_)
import Html.Events exposing (onClick, onInput)
import List
import Msg exposing (Msg(..))
import Time
import Types exposing (Model)


view : Model -> Html Msg
view model =
    let
        content =
            case model.gameState of
                NotStarted t ->
                    button [ onClick StartSearch, class "button" ] [ text "Start Search" ]

                Searching ->
                    button [ onClick StartSearch, class "button" ] [ text "Stop Search" ]

                Started g sg ->
                    gameView g sg
    in
    -- div [ style "height" "100%", style "width" "100%", class "content-container" ]
    --     [ content ]
    content


gameView : Game -> Maybe SharedGame -> Html Msg
gameView game sharedGame =
    let
        gameContent =
            case game.phase of
                TileSelection ->
                    tileSelection game sharedGame

                RegularRound ->
                    regularRound game sharedGame

                FinalRound ->
                    finalRound game

                Completed ->
                    completed game

        opponentId =
            case sharedGame of
                Just sg ->
                    sg.playerId

                Nothing ->
                    ""
    in
    div []
        [ overview game
        , gameContent
        , div [] [ text <| "PLAYER 2: " ++ opponentId ]
        ]


overview : Game -> Html Msg
overview game =
    div [] [ text <| String.fromInt <| Time.toSecond Time.utc (Time.millisToPosix (Time.posixToMillis game.currentTime - Time.posixToMillis game.startTime)) ]


tileSelection : Game -> Maybe SharedGame -> Html Msg
tileSelection game sharedGame =
    let
        getConsonantsButton =
            if List.length game.availableTiles >= tileListMax || hasMaxConsonants game.availableTiles then
                button [ onClick <| GetConsonant game, disabled True, class "button" ] [ text "Consonant" ]

            else
                button [ onClick <| GetConsonant game, class "button" ] [ text "Consonant" ]

        getVowelsButton =
            if List.length game.availableTiles >= tileListMax || hasMaxVowels game.availableTiles then
                button [ onClick <| GetVowel game, disabled True, class "button" ] [ text "Vowel" ]

            else
                button [ onClick <| GetVowel game, class "button" ] [ text "Vowel" ]
    in
    div [ classList [ ( "flex", True ), ( "flex-col", True ) ] ]
        [ getConsonantsButton
        , getVowelsButton
        , button [ onClick <| GetRandom, class "button" ] [ text "9 Random Letters" ]
        , availableTiles game sharedGame
        ]


regularRound : Game -> Maybe SharedGame -> Html Msg
regularRound game sharedGame =
    div [ classList [ ( "flex", True ), ( "flex-row", True ) ] ]
        [ button [ onClick <| ShuffleTiles game, class "button" ] [ text "Shuffle" ]
        , availableTiles game sharedGame
        , selectedTiles game sharedGame
        , button [ onClick <| Submit game sharedGame, class "button" ] [ text "Submit" ]
        ]


finalRound : Game -> Html Msg
finalRound game =
    div [] [ text "Final Round" ]


completed : Game -> Html Msg
completed game =
    div [] [ text "Completed Game" ]


availableTiles : Game -> Maybe SharedGame -> Html Msg
availableTiles game sharedGame =
    let
        tileContent =
            List.indexedMap
                (\idx tile ->
                    if tile.hidden then
                        div [] [ text "Hidden" ]

                    else
                        div []
                            [ button [ onClick <| SelectTile game sharedGame idx tile, class "button" ] [ text <| String.fromChar tile.letter ++ " / " ++ String.fromInt tile.value ]
                            ]
                )
                game.availableTiles
    in
    div [] <| tileContent


selectedTiles : Game -> Maybe SharedGame -> Html Msg
selectedTiles game sharedGame =
    let
        tileContent =
            List.indexedMap
                (\idx tile ->
                    div []
                        [ button [ onClick <| RemoveTile game sharedGame tile.originalIndex idx, class "button" ] [ text <| String.fromChar tile.letter ++ " / " ++ String.fromInt tile.value ]
                        ]
                )
                game.selectedTiles
    in
    div [] <| tileContent
