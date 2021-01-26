module View exposing (view)

import Game exposing (Game, GameState(..), Phase(..))
import Helper exposing (hasMaxConsonants, hasMaxVowels)
import Html exposing (Html, button, div, input, label, text)
import Html.Attributes as Attrs exposing (checked, class, classList, disabled, style, title, type_, value)
import Html.Events exposing (onCheck, onClick, onInput)
import List
import Msg exposing (Msg(..))
import Tailwind exposing (tailwind, withClasses)
import Tailwind.Classes exposing (border, border_black, content_center, flex, flex_col, flex_row, font_bold, inline_flex, items_center, justify_center, justify_start, m_1, m_10, m_2, m_24, m_5, mb_10, mb_2, mt_2, p_1, p_2, p_3, pb_1, pl_1, pl_2, pr_1, pr_2, pt_1, rounded, text_2xl, text_center, text_justify, text_left, w_16, w_1over4, w_48)
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
    let
        getConsonantsButton =
            if List.length game.availableTiles >= 9 || hasMaxConsonants game.availableTiles then
                button [ onClick <| GetConsonant game, disabled True, class "button" ] [ text "Consonant" ]

            else
                button [ onClick <| GetConsonant game, class "button" ] [ text "Consonant" ]

        getVowelsButton =
            if List.length game.availableTiles >= 9 || hasMaxVowels game.availableTiles then
                button [ onClick <| GetVowel game, disabled True, class "button" ] [ text "Vowel" ]

            else
                button [ onClick <| GetVowel game, class "button" ] [ text "Vowel" ]
    in
    div [ tailwind [ flex, flex_col ] ]
        [ getConsonantsButton
        , getVowelsButton
        , button [ onClick <| GetRandom, class "button" ] [ text "9 Random Letters" ]
        , availableTiles game
        ]


regularRound : Game -> Html Msg
regularRound game =
    div [ tailwind [ flex, flex_row ] ]
        [ button [ onClick <| ShuffleTiles game, class "button" ] [ text "Shuffle" ]
        , availableTiles game
        , selectedTiles game
        ]


finalRound : Game -> Html Msg
finalRound game =
    div [] [ text "Final Round" ]


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
