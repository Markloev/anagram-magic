module Update exposing (update)

import Browser.Dom as Dom
import Helper exposing (return)
import Http exposing (Error(..))
import Prelude exposing (iff)
import Task
import Time
import Types
    exposing
        ( Model
        , Msg(..)
        , GameState(..)
        , initGame
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DoNothing ->
            return model []

        FocusOn id ->
            ( model, Dom.focus id |> Task.attempt FocusResult )

        FocusResult _ ->
            ( model, Cmd.none )
        
        GetResponse _ ->
            ( model, Cmd.none )
        
        Tick posix ->
            let
                updatedGameState =
                    case model.gameState of
                        Stopped ->
                            model.gameState
                        
                        Started g ->
                            let
                                isStart =
                                    Time.posixToMillis g.startTime == 0

                                newGameState =
                                    { g
                                        | currentTime = posix
                                        , startTime = iff isStart posix g.startTime
                                    }
                            in
                            Started newGameState
            in
            ( { model | gameState = updatedGameState }, Cmd.none )
        
        StartGame ->
            ( { model | gameState = Started initGame}, Cmd.none)