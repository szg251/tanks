port module Channel exposing
    ( Msg(..)
    , connect
    , fire
    , join
    , moveTank
    , moveTurret
    , push
    , receive
    , responseToMsg
    )

import GameState exposing (GameState, Tank)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode


port connect : String -> Cmd msg


port join : String -> Cmd msg


type alias Push =
    { event : String, payload : Value }


type alias Response =
    { event : String, payload : Value }


port receive : (Response -> msg) -> Sub msg


port push : Push -> Cmd msg


type Msg
    = NoOp
    | Sync GameState


moveTank : Int -> Cmd msg
moveTank val =
    push (Push "move" <| Encode.object [ ( "move", Encode.int val ) ])


moveTurret : Float -> Cmd msg
moveTurret val =
    push (Push "move_turret" <| Encode.object [ ( "angle", Encode.float val ) ])


fire : Cmd msg
fire =
    push (Push "fire" <| Encode.object [])


responseToMsg : Response -> Msg
responseToMsg response =
    if response.event == "sync" then
        Decode.decodeValue GameState.decoder response.payload
            |> Result.map Sync
            |> Result.withDefault NoOp

    else
        NoOp
