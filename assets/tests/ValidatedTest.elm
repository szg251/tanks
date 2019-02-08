module ValidatedTest exposing (suite)

import Expect exposing (Expectation)
import Test exposing (..)
import Validated exposing (Validated(..), combine, max, min, regex)


suite : Test
suite =
    concat
        [ describe "min string length"
            [ test "valid"
                (\_ ->
                    Expect.equal
                        (min 5 "too short" "12345")
                        (Valid "12345")
                )
            , test "invalid"
                (\_ ->
                    Expect.equal
                        (min 5 "too short" "1234")
                        (Invalid "too short" "1234")
                )
            ]
        , describe "max string length"
            [ test "valid"
                (\_ ->
                    Expect.equal
                        (max 5 "too long" "12345")
                        (Valid "12345")
                )
            , test "invalid"
                (\_ ->
                    Expect.equal
                        (max 5 "too long" "123456")
                        (Invalid "too long" "123456")
                )
            ]
        , describe "regex"
            [ test "valid"
                (\_ ->
                    Expect.equal
                        (regex "^[0-9]*$" "regex does not match" "12345")
                        (Valid "12345")
                )
            , test "invalid"
                (\_ ->
                    Expect.equal
                        (regex "^[0-9]*$" "regex does not match" "123a5")
                        (Invalid "regex does not match" "123a5")
                )
            ]
        , describe "combined validators"
            [ test "valid"
                (\_ ->
                    Expect.equal
                        (combine [ min 5 "too short", max 10 "too long" ] "12345")
                        (Valid "12345")
                )
            , test "first validation fails"
                (\_ ->
                    Expect.equal
                        (combine [ min 5 "too short", max 10 "too long" ] "1234")
                        (Invalid "too short" "1234")
                )
            , test "second validation fails"
                (\_ ->
                    Expect.equal
                        (combine [ min 5 "too short", max 10 "too long" ] "12345678901")
                        (Invalid "too long" "12345678901")
                )
            , test "both validation fails"
                (\_ ->
                    Expect.equal
                        (combine [ min 5 "too short", max 1 "too long" ] "1234")
                        (Invalid "too short" "1234")
                )
            ]
        ]
