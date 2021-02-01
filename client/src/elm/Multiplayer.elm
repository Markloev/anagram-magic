module Multiplayer exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import WebSocket


type Event
    = Searching
    | PlayerFound String Bool
    | ChangePhase


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
                        Decode.succeed ChangePhase

                    _ ->
                        Decode.fail "Unknown server event: "
            )


searchingEncoder : String -> Value
searchingEncoder playerId =
    WebSocket.eventEncoder "searching" (Encode.string playerId)


changePhaseEncoder : String -> Value
changePhaseEncoder playerId =
    WebSocket.eventEncoder "changePhase" (Encode.string playerId)
