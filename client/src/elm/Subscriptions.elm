module Subscriptions exposing (subscriptions)

import Browser.Events
import Constants exposing (timeInterval)
import Game exposing (GameState(..), Tile, isRunning)
import Json.Decode as Decode
import Msg exposing (Msg(..))
import Ports
import Prelude exposing (iff)
import Time
import Types exposing (Model)


subscriptions : Model -> Sub Msg
subscriptions { gameState } =
    Sub.batch
        [ iff (isRunning gameState) tick Sub.none
        , Browser.Events.onKeyUp (Decode.map (KeyPressed gameState) keyDecoder)
        , Ports.receiveRandomTiles (decodeListTiles >> ReceiveRandomTiles gameState)
        , Ports.receiveShuffledTiles (decodeListTiles >> ReceiveShuffledTiles gameState)
        ]


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
