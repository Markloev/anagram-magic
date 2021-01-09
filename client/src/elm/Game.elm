module Game exposing (..)


type GameState
    = NotStarted
    | Running
    | Stopped


isRunning : GameState -> Bool
isRunning gameState =
    gameState == Running
