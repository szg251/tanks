module ValidatedTest exposing (suite)

import Expect exposing (Expectation)
import Test exposing (..)
import Validated exposing (Validated(..), combine, max, min)


suite : Test
suite =
    concat
        [ describe "min string length"
            [ test "valid"
                (\_ ->
                    Expect.equal
                        (min 5 "12345")
                        (Valid "12345")
                )
            , test "invalid"
                (\_ ->
                    Expect.equal
                        (min 5 "1234")
                        (Invalid "too short" "1234")
                )
            ]
        , describe "max string length"
            [ test "valid"
                (\_ ->
                    Expect.equal
                        (max 5 "12345")
                        (Valid "12345")
                )
            , test "invalid"
                (\_ ->
                    Expect.equal
                        (max 5 "123456")
                        (Invalid "too long" "123456")
                )
            ]
        , describe "combined validators"
            [ test "valid"
                (\_ ->
                    Expect.equal
                        (combine [ min 5, max 10 ] "12345")
                        (Valid "12345")
                )
            , test "first validation fails"
                (\_ ->
                    Expect.equal
                        (combine [ min 5, max 10 ] "1234")
                        (Invalid "too short" "1234")
                )
            , test "second validation fails"
                (\_ ->
                    Expect.equal
                        (combine [ min 5, max 10 ] "12345678901")
                        (Invalid "too long" "12345678901")
                )
            , test "both validation fails"
                (\_ ->
                    Expect.equal
                        (combine [ min 5, max 1 ] "1234")
                        (Invalid "too short" "1234")
                )
            ]
        ]
