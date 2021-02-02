module Multiplayer exposing (..)

import Game exposing (Tile)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import WebSocket


type Event
    = Searching
    | PlayerFound String Bool
    | ChangePhase (List Tile)


eventDecoder : Decoder Event
eventDecoder =
    Decode.field "EventType" Decode.string
        |> Decode.andThen
            (\event ->
                case event of
                    "playerFound" ->
                        Decode.map2 PlayerFound
                            (Decode.at [ "Data", "PlayerID" ] Decode.string)
                            (Decode.at [ "Data", "TileSelectionTurn" ] Decode.bool)

                    "changePhase" ->
                        Decode.map ChangePhase
                            (Decode.at [ "Data", "tiles" ] listTilesDecoder)

                    _ ->
                        Decode.fail "Unknown server event: "
            )


searchingEncoder : String -> Value
searchingEncoder playerId =
    WebSocket.eventEncoder "searching" (Encode.string playerId)


changePhaseEncoder : List Tile -> String -> Value
changePhaseEncoder tiles playerId =
    Encode.object
        [ ( "playerId", Encode.string playerId )
        , ( "tiles", listTilesEncoder tiles )
        ]
        |> WebSocket.eventEncoder "changePhase"


tileEncoder : Tile -> Encode.Value
tileEncoder tile =
    Encode.object
        [ ( "letter", tile.letter |> Char.toCode |> Encode.int )
        , ( "value", tile.value |> Encode.int )
        , ( "originalIndex", tile.originalIndex |> Encode.int )
        , ( "hidden", tile.hidden |> Encode.bool )
        ]


listTilesEncoder : List Tile -> Encode.Value
listTilesEncoder tiles =
    tiles |> Encode.list tileEncoder


tileDecoder : Decode.Decoder Tile
tileDecoder =
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


listTilesDecoder : Decode.Decoder (List Tile)
listTilesDecoder =
    Decode.list tileDecoder


listTilesDecoderResult : Decode.Value -> Result Decode.Error (List Tile)
listTilesDecoderResult =
    Decode.list tileDecoder |> Decode.decodeValue
