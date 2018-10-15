port module Channel exposing
    ( Msg(..)
    , fire
    , join
    , moveTank
    , moveTurret
    , push
    , receive
    , responseToMsg
    )

import Debug
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Tank exposing (Tank)


port join : String -> Cmd msg


type alias Push =
    { event : String, payload : Value }


type alias Response =
    { event : String, payload : Value }


port receive : (Response -> msg) -> Sub msg


port push : Push -> Cmd msg


type Msg
    = NoOp
    | UpdateTanks (List Tank)


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
        Decode.decodeValue gameStateDecoder response.payload
            |> Result.map UpdateTanks
            |> Result.withDefault NoOp

    else
        NoOp


gameStateDecoder : Decoder (List Tank)
gameStateDecoder =
    Decode.field "tanks" (Decode.list Tank.decoder)
