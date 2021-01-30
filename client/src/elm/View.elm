module View exposing (view)

import Constants exposing (tileListMax)
import Game exposing (Game, GameState(..), Phase(..))
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
                    button [ onClick StartGame, class "button" ] [ text model.socketMessage ]

                Started g ->
                    gameView g

        msgs =
            List.map (\msg -> div [] [ text msg ]) model.testReceivedString
    in
    -- div [ style "height" "100%", style "width" "100%", class "content-container" ]
    --     [ content ]
    div []
        [ Html.input [ type_ "text", onInput ChangeString ] [ text model.testString ]
        , div [] <| msgs
        , button [ onClick SendMessage, class "button" ] [ text "Send Message" ]
        ]


gameView : Game -> Html Msg
gameView game =
    let
        gameContent =
            case game.phase of
                TileSelection ->
                    tileSelection game

                RegularRound ->
                    regularRound game

                FinalRound ->
                    finalRound game

                Completed ->
                    completed game
    in
    div []
        [ overview game
        , gameContent
        ]


overview : Game -> Html Msg
overview game =
    div [] [ text <| String.fromInt <| Time.toSecond Time.utc (Time.millisToPosix (Time.posixToMillis game.currentTime - Time.posixToMillis game.startTime)) ]


tileSelection : Game -> Html Msg
tileSelection game =
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
        , availableTiles game
        ]


regularRound : Game -> Html Msg
regularRound game =
    div [ classList [ ( "flex", True ), ( "flex-row", True ) ] ]
        [ button [ onClick <| ShuffleTiles game, class "button" ] [ text "Shuffle" ]
        , availableTiles game
        , selectedTiles game
        , button [ onClick <| Submit game, class "button" ] [ text "Submit" ]
        ]


finalRound : Game -> Html Msg
finalRound game =
    div [] [ text "Final Round" ]


completed : Game -> Html Msg
completed game =
    div [] [ text "Completed Game" ]


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
                            [ button [ onClick <| SelectTile game idx tile, class "button" ] [ text <| String.fromChar tile.letter ++ " / " ++ String.fromInt tile.value ]
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
                        [ button [ onClick <| RemoveTile game tile.originalIndex idx, class "button" ] [ text <| String.fromChar tile.letter ++ " / " ++ String.fromInt tile.value ]
                        ]
                )
                game.selectedTiles
    in
    div [] <| tileContent
