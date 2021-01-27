module Subscriptions exposing (subscriptions)

import Browser.Events
import Constants exposing (timeInterval)
import Game exposing (GameState(..), Tile)
import Json.Decode as Decode
import Msg exposing (Msg(..))
import Ports
import Time
import Types exposing (Model)


subscriptions : Model -> Sub Msg
subscriptions { gameState } =
    let
        subs =
            case gameState of
                Started g ->
                    Sub.batch
                        [ tick
                        , Browser.Events.onKeyUp (Decode.map (KeyPressed g) keyDecoder)
                        , Ports.receiveRandomTiles (decodeListTiles >> ReceiveRandomTiles g)
                        , Ports.receiveShuffledTiles (decodeListTiles >> ReceiveShuffledTiles g)
                        ]

                NotStarted ->
                    Sub.none
    in
    subs


tick : Sub Msg
tick =
    Time.every timeInterval Tick


decodeTile : Decode.Decoder Tile
decodeTile =
    Decode.map4 Tile
        (Decode.field
            "letter"
            (Decode.int |> Decode.map Char.fromCode)
        )
        (Decode.field
            "value"
            Decode.int
        )
        (Decode.field
            "originalIndex"
            Decode.int
        )
        (Decode.field
            "hidden"
            Decode.bool
        )


decodeListTiles : Decode.Value -> Result Decode.Error (List Tile)
decodeListTiles =
    Decode.list decodeTile |> Decode.decodeValue


keyDecoder : Decode.Decoder String
keyDecoder =
    Decode.field "key" Decode.string
