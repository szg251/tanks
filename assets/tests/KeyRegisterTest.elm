module KeyRegisterTest exposing (suite)

import Browser.Events exposing (Visibility(..))
import Dict
import Expect exposing (Expectation)
import KeyRegister exposing (Key, KeyRegister, KeyState(..), Msg(..), update)
import Test exposing (..)


suite : Test
suite =
    describe "key press update"
        [ test "key pressed for the first time"
            (\_ ->
                let
                    msg =
                        KeyPressed { id = "ArrowUp", state = KeyDown }

                    keyChanges =
                        KeyRegister.init
                            |> update msg
                            |> Tuple.second
                in
                Expect.equal keyChanges [ Key "ArrowUp" KeyDown ]
            )
        , test "key released"
            (\_ ->
                let
                    msg1 =
                        KeyPressed { id = "ArrowUp", state = KeyDown }

                    msg2 =
                        KeyPressed { id = "ArrowUp", state = KeyUp }

                    keyChanges =
                        KeyRegister.init
                            |> update msg1
                            |> Tuple.first
                            |> update msg2
                            |> Tuple.second
                in
                Expect.equal keyChanges [ Key "ArrowUp" KeyUp ]
            )
        , test "key pressed two times"
            (\_ ->
                let
                    keyChanges =
                        testUpdateSeq
                            [ KeyPressed { id = "ArrowUp", state = KeyDown }
                            , KeyPressed { id = "ArrowUp", state = KeyUp }
                            , KeyPressed { id = "ArrowUp", state = KeyDown }
                            ]
                in
                Expect.equal keyChanges [ Key "ArrowUp" KeyDown ]
            )
        , test "no keys changed"
            (\_ ->
                let
                    keyChanges =
                        testUpdateSeq
                            [ KeyPressed { id = "ArrowUp", state = KeyDown }
                            , KeyPressed { id = "ArrowUp", state = KeyDown }
                            ]
                in
                Expect.equal keyChanges []
            )
        , test "visibility changed to hidden resets all keys"
            (\_ ->
                let
                    keyChanges =
                        testUpdateSeq
                            [ KeyPressed { id = "ArrowUp", state = KeyDown }
                            , KeyPressed { id = "ArrowDown", state = KeyDown }
                            , KeyPressed { id = "ArrowDown", state = KeyUp }
                            , KeyPressed { id = "ArrowLeft", state = KeyDown }
                            , KeyPressed { id = "ArrowRight", state = KeyDown }
                            , KeyPressed { id = "ArrowRight", state = KeyUp }
                            , VisibilityChanged Hidden
                            ]
                in
                Expect.equal keyChanges [ Key "ArrowLeft" KeyUp, Key "ArrowUp" KeyUp ]
            )
        ]


testUpdateSeq : List KeyRegister.Msg -> List Key
testUpdateSeq msgs =
    let
        init =
            ( KeyRegister.init, [] )

        pipeUpdate nextMsg ( currentKeyRegister, _ ) =
            update nextMsg currentKeyRegister
    in
    List.foldl pipeUpdate init msgs |> Tuple.second
