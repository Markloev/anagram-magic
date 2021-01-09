module Update exposing (update)

import Browser.Dom as Dom
import Helper exposing (return)
import Msg exposing (Msg(..))
import Prelude exposing (iff)
import Task
import Time
import Types
    exposing
        ( ColorTheme(..)
        , Model
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DoNothing ->
            return model []

        Resize screen ->
            ( { model | screen = screen }, Cmd.none )

        SetViewportCb ->
            ( model, Cmd.none )

        FocusOn id ->
            ( model, Dom.focus id |> Task.attempt FocusResult )

        FocusResult _ ->
            ( model, Cmd.none )

        GetResponse _ ->
            ( model, Cmd.none )

        Tick posix ->
            let
                isStart =
                    Time.posixToMillis model.startTime == 0
            in
            { model
                | currentTime = posix
                , startTime = iff isStart posix model.startTime
            }
                |> tick


addNone : Model -> ( Model, Cmd Msg )
addNone model =
    ( model, Cmd.none )


tick : Model -> ( Model, Cmd Msg )
tick model =
    model |> addNone
