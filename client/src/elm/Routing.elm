module Routing exposing (goTo, router)

import Ports
import Types exposing (Route(..))
import Url
import Url.Builder exposing (absolute)
import Url.Parser exposing (map, oneOf, s)


goTo : Route -> Cmd msg
goTo route =
    Ports.pushUrl <|
        case route of
            RouteHome ->
                absolute [ "home" ] []

            RouteAbout ->
                absolute [ "about" ] []

            RouteNotFound ->
                absolute [] []


router : String -> Route
router =
    Url.fromString
        >> Maybe.andThen
            (Url.Parser.parse
                (Url.Parser.oneOf
                    [ map RouteHome <| s "home"
                    , map RouteAbout <| s "about"
                    ]
                )
            )
        >> Maybe.withDefault RouteNotFound
