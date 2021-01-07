module Types exposing (ColorTheme(..), Model, Msg(..), Route(..), Screen, View(..), emptyModel)

import Browser.Dom as Dom
import Http


type alias Model =
    { screen : Screen
    , view : View
    , errorMessage : Maybe String
    }


emptyModel : Model
emptyModel =
    { screen = { width = 0, height = 0 }
    , view = ViewHome
    , errorMessage = Nothing
    }

type Msg
    = DoNothing
    | UrlChange Route
    | Resize Screen
    | NavTo Route
    | FocusOn String
    | FocusResult (Result Dom.Error ())
    | SetViewportCb
    | GetResponse (Result Http.Error String)


type alias Screen =
    { width : Int
    , height : Int
    }


type View
    = ViewHome
    | ViewAbout


type Route
    = RouteHome
    | RouteAbout
    | RouteNotFound


type ColorTheme
    = Light
    | Dark
