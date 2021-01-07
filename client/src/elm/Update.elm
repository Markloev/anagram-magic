module Update exposing (update)

import Browser.Dom as Dom
import Helper exposing (return)
import Http exposing (Error(..))
import Routing
import Task
import Types
    exposing
        ( ColorTheme(..)
        , Model
        , Msg(..)
        , Route(..)
        , View(..)
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DoNothing ->
            return model []

        Resize screen ->
            ( { model | screen = screen }, Cmd.none )

        UrlChange route ->
            case route of
                RouteHome ->
                    ( { model | view = ViewHome, errorMessage = Nothing }, Cmd.none )

                RouteAbout ->
                    ( { model | view = ViewAbout, errorMessage = Nothing }, Cmd.none )

                RouteNotFound ->
                    ( { model | errorMessage = Nothing }, Cmd.none )

        NavTo route ->
            ( model, Routing.goTo route )

        SetViewportCb ->
            ( model, Cmd.none )

        FocusOn id ->
            ( model, Dom.focus id |> Task.attempt FocusResult )

        FocusResult _ ->
            ( model, Cmd.none )
        
        GetResponse _ ->
            ( model, Cmd.none )
