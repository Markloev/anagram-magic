module Rest exposing (..)

import Http
import Json.Decode as JD
import Json.Encode as JE
import Msg exposing (Msg(..))


getWordValidity : String -> Cmd Msg
getWordValidity word =
    Http.post
        { url =
            "http://localhost:8080/word"
        , body =
            encodeWord word
                |> Http.jsonBody
        , expect =
            Http.expectString GetWordValidityResponse
        }


getRandomWord : Cmd Msg
getRandomWord =
    Http.get
        { url =
            "http://localhost:8080/randomWord"
        , expect =
            Http.expectString GetRandomWordResponse
        }


encodeWord : String -> JE.Value
encodeWord str =
    JE.object [ ( "word", JE.string str ) ]
