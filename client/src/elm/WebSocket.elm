module WebSocket exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Ports exposing (fromSocket, toSocket)


type SocketStatus
    = Unopened
    | Requested
    | SocketConnected ConnectionInfo
    | SocketClosed Int (Maybe String)


type alias ConnectionInfo =
    { protocol : String
    , extensions : String
    , url : String
    }


initConnectionInfo : ConnectionInfo
initConnectionInfo =
    { protocol = ""
    , extensions = ""
    , url = ""
    }


connect : String -> List String -> Cmd msg
connect url protocols =
    message "connect"
        (Encode.object
            [ ( "url", Encode.string url )
            , ( "protocols", Encode.list Encode.string protocols )
            ]
        )
        |> toSocket


disconnect : String -> Cmd msg
disconnect url =
    message "disconnect"
        (Encode.object
            [ ( "url", Encode.string url ) ]
        )
        |> toSocket


sendJSON : ConnectionInfo -> String -> Cmd msg
sendJSON connection text =
    message "sendJSON"
        (Encode.object
            [ ( "url", Encode.string connection.url )
            , ( "message", Encode.string text )
            ]
        )
        |> toSocket


sendJsonString : ConnectionInfo -> Value -> Cmd msg
sendJsonString connection =
    sendJSON connection << Encode.encode 0


type Event
    = Connected ConnectionInfo
    | StringMessage ConnectionInfo String
    | Closed ConnectionInfo Int (Maybe String)
    | Error ConnectionInfo
    | BadMessage String


events : (Event -> msg) -> Sub msg
events msg =
    fromSocket
        (\val ->
            case Decode.decodeValue eventDecoder val of
                Ok event ->
                    msg event

                Err decodeErr ->
                    msg (BadMessage (Decode.errorToString decodeErr))
        )


eventDecoder : Decoder Event
eventDecoder =
    Decode.field "msgType" Decode.string
        |> Decode.andThen
            (\msgType ->
                case msgType of
                    "connected" ->
                        Decode.map Connected
                            (Decode.field "msg" connectionDecoder)

                    "stringMessage" ->
                        Decode.map2 StringMessage
                            (Decode.field "msg" connectionDecoder)
                            (Decode.at [ "msg", "data" ] Decode.string)

                    "closed" ->
                        Decode.map3 Closed
                            (Decode.field "msg" connectionDecoder)
                            (Decode.at [ "msg", "unsentBytes" ] Decode.int)
                            (Decode.at [ "msg", "reason" ] (Decode.nullable Decode.string))

                    "error" ->
                        Decode.map Error
                            (Decode.field "msg" connectionDecoder)

                    _ ->
                        Decode.succeed (BadMessage ("Unknown message type: " ++ msgType))
            )


connectionDecoder : Decoder ConnectionInfo
connectionDecoder =
    Decode.map3 ConnectionInfo
        (Decode.field "protocol" Decode.string)
        (Decode.field "extensions" Decode.string)
        (Decode.field "url" Decode.string)


message : String -> Value -> Value
message msgType msg =
    Encode.object
        [ ( "msgType", Encode.string msgType )
        , ( "msg", msg )
        ]


eventEncoder : String -> Value -> Value
eventEncoder eventType data =
    Encode.object
        [ ( "eventType", Encode.string eventType )
        , ( "data", data )
        ]
