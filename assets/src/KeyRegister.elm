module KeyRegister exposing (Key, KeyRegister, KeyState(..), Msg(..), init, onKeyDown, onKeyUp, onVisibilityChange, update)

import Browser.Events exposing (Visibility(..))
import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)


type KeyRegister
    = KeyRegister (Dict String KeyState)


type Msg
    = KeyPressed Key
    | VisibilityChanged Visibility


type alias Key =
    { id : String, state : KeyState }


type KeyState
    = KeyUp
    | KeyDown


init : KeyRegister
init =
    KeyRegister Dict.empty


update : Msg -> KeyRegister -> ( KeyRegister, List Key )
update msg (KeyRegister keyRegister) =
    case msg of
        KeyPressed key ->
            let
                prevKeyState =
                    Dict.get key.id keyRegister
            in
            if prevKeyState == Just key.state then
                ( KeyRegister keyRegister, [] )

            else
                ( KeyRegister <| Dict.insert key.id key.state keyRegister, [ key ] )

        VisibilityChanged visibility ->
            if visibility == Hidden then
                let
                    diff =
                        keyRegister
                            |> Dict.toList
                            |> List.filter
                                (\( _, state ) -> state == KeyDown)
                            |> List.map
                                (\( id, state ) ->
                                    { id = id, state = KeyUp }
                                )
                in
                ( init, diff )

            else
                ( KeyRegister keyRegister, [] )


keyDecoder : KeyState -> (Key -> Msg) -> Decoder Msg
keyDecoder keyState toMsg =
    Decode.field "key" Decode.string
        |> Decode.map (\key -> toMsg { id = key, state = keyState })


onKeyUp : Decoder Msg
onKeyUp =
    keyDecoder KeyUp KeyPressed


onKeyDown : Decoder Msg
onKeyDown =
    keyDecoder KeyDown KeyPressed


onVisibilityChange : Visibility -> Msg
onVisibilityChange =
    VisibilityChanged
