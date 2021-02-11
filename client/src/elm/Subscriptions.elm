module Subscriptions exposing (subscriptions)

import Browser.Events
import Constants exposing (timeInterval)
import Game exposing (GameState(..))
import Json.Decode as Decode
import Msg exposing (Msg(..))
import Multiplayer exposing (listTilesDecoderResult)
import Ports
import Time
import Types exposing (Model)
import WebSocket exposing (SocketStatus(..))


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        webSocketSub =
            WebSocket.events
                (\event ->
                    case event of
                        WebSocket.Connected info ->
                            SocketConnect info

                        WebSocket.StringMessage _ message ->
                            ReceivedString message

                        WebSocket.Closed _ unsentBytes reason ->
                            Msg.SocketClosed unsentBytes reason

                        WebSocket.Error _ ->
                            Msg.Error "WebSocket Error"

                        WebSocket.BadMessage error ->
                            Msg.Error error
                )

        subs =
            case model.gameState of
                Started g ->
                    Sub.batch
                        [ tick
                        , Ports.receiveRandomTiles (listTilesDecoderResult >> ReceiveRandomTiles g)
                        , Ports.receiveShuffledTiles (listTilesDecoderResult >> ReceiveShuffledTiles g)
                        ]

                _ ->
                    Sub.none
    in
    Sub.batch
        [ webSocketSub
        , Browser.Events.onKeyUp (Decode.map KeyPressed keyDecoder)
        , subs
        ]


tick : Sub Msg
tick =
    Time.every timeInterval Tick


keyDecoder : Decode.Decoder String
keyDecoder =
    Decode.field "key" Decode.string
