module Types exposing (ColorTheme(..), Model, Msg(..), Screen, emptyModel)

import Browser.Dom as Dom
import Http


type alias Model =
    { screen : Screen
    , errorMessage : Maybe String
    }


emptyModel : Model
emptyModel =
    { screen = { width = 0, height = 0 }
    , errorMessage = Nothing
    }

type Msg
    = DoNothing
    | Resize Screen
    | FocusOn String
    | FocusResult (Result Dom.Error ())
    | SetViewportCb
    | GetResponse (Result Http.Error String)


type alias Screen =
    { width : Int
    , height : Int
    }


type ColorTheme
    = Light
    | Dark
