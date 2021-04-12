module Subscriptions exposing (subscriptions)

import Browser.Events
import Game exposing (GameState(..), Phase(..))
import Json.Decode as Decode
import Model exposing (Model)
import Msg exposing (Msg(..))
import Ports
import WebSocket.Multiplayer exposing (listTilesDecoderResult)
import WebSocket.WebSocket as WebSocket exposing (SocketStatus(..))


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        webSocketSub =
            WebSocket.events
                (\event ->
                    case event of
                        WebSocket.Connected info ->
                            WebSocketConnect info

                        WebSocket.StringMessage _ message ->
                            ReceivedString message

                        WebSocket.Closed _ unsentBytes reason ->
                            WebSocketClosed unsentBytes reason

                        WebSocket.Error _ ->
                            Msg.Error "WebSocket Error"

                        WebSocket.BadMessage error ->
                            Msg.Error error
                )

        subs =
            case model.gameState of
                Started g ->
                    if g.phase == CompletedGame then
                        Sub.none

                    else
                        Sub.batch
                            [ Ports.receiveRandomTiles
                                (listTilesDecoderResult >> ReceiveRandomTiles g)
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


keyDecoder : Decode.Decoder String
keyDecoder =
    Decode.field "key" Decode.string
