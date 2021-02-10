module Example exposing (..)

import Expect
import Test exposing (..)


{-| See <https://github.com/elm-community/elm-test>
-}
unitTest : Test
unitTest =
    describe "simple unit test"
        [ test "1 + 1 = 2" <|
            \() ->
                1 + 1 |> Expect.equal 2
        ]
