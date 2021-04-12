module WebSocket.Multiplayer exposing (..)

import Game exposing (Phase(..), SpecificRound(..), Tile)
import Json.Decode as Decode
import Json.Encode as Encode
import Utils.CoreHelpers exposing (listTilesEncoder)
import WebSocket.WebSocket


type Event
    = PlayerFound String Bool
    | RoundComplete (Maybe String)
    | ReceiveTiles (List Tile)
    | ChangeTiles String
    | SubmitTurn
    | SubmitTurnComplete Bool Bool
    | ForceEndGame


eventDecoder : Decode.Decoder Event
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
                        Decode.maybe
                            (Decode.at
                                [ "Data", "randomWord" ]
                                Decode.string
                            )
                            |> Decode.map
                                RoundComplete

                    "receiveTiles" ->
                        Decode.map ReceiveTiles
                            (Decode.at [ "Data", "tiles" ] listTilesDecoder)

                    "changeTiles" ->
                        Decode.map ChangeTiles
                            (Decode.at [ "Data", "selectedWord" ] Decode.string)

                    "submitTurn" ->
                        Decode.succeed SubmitTurn

                    "submitTurnComplete" ->
                        Decode.map2 SubmitTurnComplete
                            (Decode.at [ "Data", "playerValidWord" ] Decode.bool)
                            (Decode.at [ "Data", "opponentValidWord" ] Decode.bool)

                    "forceEndGame" ->
                        Decode.succeed ForceEndGame

                    _ ->
                        Decode.fail "Unknown server event: "
            )


basicEncoder : String -> String -> Encode.Value
basicEncoder eventType playerId =
    WebSocket.WebSocket.eventEncoder eventType (Encode.string playerId)


receiveTilesEncoder : List Tile -> String -> Encode.Value
receiveTilesEncoder tiles playerId =
    Encode.object
        [ ( "playerId", Encode.string playerId )
        , ( "tiles", listTilesEncoder tiles )
        ]
        |> WebSocket.WebSocket.eventEncoder "receiveTiles"


submitTurnEncoder : Phase -> List Tile -> String -> Encode.Value
submitTurnEncoder phase tiles playerId =
    Encode.object
        [ ( "playerId", Encode.string playerId )
        , ( "tiles", listTilesEncoder tiles )
        , phaseEncoder phase
        ]
        |> WebSocket.WebSocket.eventEncoder "submitTurn"


sharedTilesEncoder : List Tile -> String -> Encode.Value
sharedTilesEncoder tiles playerId =
    Encode.object
        [ ( "playerId", Encode.string playerId )
        , ( "tiles", listTilesEncoder tiles )
        ]
        |> WebSocket.WebSocket.eventEncoder "changeTiles"


roundCompleteEncoder : Phase -> String -> Encode.Value
roundCompleteEncoder phase playerId =
    Encode.object
        [ ( "playerId", Encode.string playerId )
        , phaseEncoder phase
        ]
        |> WebSocket.WebSocket.eventEncoder "roundComplete"


phaseEncoder : Phase -> ( String, Encode.Value )
phaseEncoder phase =
    case phase of
        CompletedRound FourthRound ->
            ( "phase", Encode.string "finalRound" )

        Round FinalRound ->
            ( "phase", Encode.string "finalRound" )

        _ ->
            ( "phase", Encode.string "regularRound" )


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
