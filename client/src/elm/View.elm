module View exposing (view)

import Game exposing (GameState(..), Game, Phase(..))
import Html exposing (Html, div, text, input, label, button)
import Html.Attributes as Attrs exposing (checked, class, classList, title, type_, style, value)
import Html.Events exposing (onClick, onCheck, onInput)
import Msg exposing (Msg(..))
import Types exposing (Model)


view : Model -> Html Msg
view model =
    let
        content =
            case model.gameState of
                NotStarted ->
                    button [ onClick StartGame, class "button" ] [ text "Start Game" ]
                
                Started g ->
                    gameView g

    in
    div [ style "height" "100%", style "width" "100%", class "content-container" ]
        [ content ]


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
    in
    gameContent


tileSelection : Game -> Html Msg
tileSelection game =
    div [] []


regularRound : Game -> Html Msg
regularRound game =
    div [] []


finalRound : Game -> Html Msg
finalRound game =
    div [] []
