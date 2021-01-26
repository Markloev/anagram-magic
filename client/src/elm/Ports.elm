port module Ports exposing (..)

import Game exposing (Tile)
import Json.Decode as Decode
import Json.Encode as Encode


port getRandomTiles : () -> Cmd msg


port getRandomConsonant : Encode.Value -> Cmd msg


port getRandomVowel : Encode.Value -> Cmd msg


port shuffleTiles : Encode.Value -> Cmd msg


port receiveRandomTiles : (Decode.Value -> msg) -> Sub msg


port receiveShuffledTiles : (Decode.Value -> msg) -> Sub msg


encodeTile : Tile -> Encode.Value
encodeTile tile =
    Encode.object
        [ ( "letter", tile.letter |> Char.toCode |> Encode.int )
        , ( "value", tile.value |> Encode.int )
        ]


encodeListTiles : List Tile -> Encode.Value
encodeListTiles tiles =
    tiles |> Encode.list encodeTile
