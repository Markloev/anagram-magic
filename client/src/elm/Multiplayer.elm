module Multiplayer exposing (..)

import Json.Decode as Decode exposing (Decoder)

type Event
  = PlayerFound String
  | Searching

eventDecoder : Decoder Event
eventDecoder =
  Decode.field "EventType" Decode.string
    |> Decode.andThen
        (\event ->
            case event of
                "playerFound" ->
                    Decode.map PlayerFound
                        (Decode.at [ "Data", "PlayerID" ] Decode.string)
                
                "searching" ->
                    Decode.succeed Searching
                
                _ ->
                    Decode.fail "Unknown server event: "
      )