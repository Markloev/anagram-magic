module Multiplayer exposing (..)

import Game exposing (Tile)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import WebSocket


type Event
    = PlayerFound String Bool
    | RoundComplete
    | ReceiveTiles (List Tile)
    | ChangeTiles (List Tile)
    | SubmitTurnComplete Bool Bool
    | SubmitTurn


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

                    "roundComplete" ->
                        Decode.succeed RoundComplete

                    "receiveTiles" ->
                        Decode.map ReceiveTiles
                            (Decode.at [ "Data", "tiles" ] listTilesDecoder)

                    "changeTiles" ->
                        Decode.map ChangeTiles
                            (Decode.at [ "Data", "tiles" ] listTilesDecoder)

                    "submitTurnComplete" ->
                        Decode.map2 SubmitTurnComplete
                            (Decode.at [ "Data", "playerValidWord" ] Decode.bool)
                            (Decode.at [ "Data", "opponentValidWord" ] Decode.bool)

                    "submitTurn" ->
                        Decode.succeed SubmitTurn

                    _ ->
                        Decode.fail "Unknown server event: "
            )


basicEncoder : String -> String -> Value
basicEncoder eventType playerId =
    WebSocket.eventEncoder eventType (Encode.string playerId)


receiveTilesEncoder : List Tile -> String -> Value
receiveTilesEncoder tiles playerId =
    Encode.object
        [ ( "playerId", Encode.string playerId )
        , ( "tiles", listTilesEncoder tiles )
        ]
        |> WebSocket.eventEncoder "receiveTiles"


submitTurnEncoder : List Tile -> String -> Value
submitTurnEncoder tiles playerId =
    Encode.object
        [ ( "playerId", Encode.string playerId )
        , ( "tiles", listTilesEncoder tiles )
        ]
        |> WebSocket.eventEncoder "submitTurn"


sharedTilesEncoder : List Tile -> String -> Value
sharedTilesEncoder tiles playerId =
    Encode.object
        [ ( "playerId", Encode.string playerId )
        , ( "tiles", listTilesEncoder tiles )
        ]
        |> WebSocket.eventEncoder "changeTiles"


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
    Decode.list tileDecoder
        |> Decode.decodeValue
