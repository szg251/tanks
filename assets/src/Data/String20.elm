module Data.String20 exposing (String20, create, decoder, empty, encode, length, value)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


type String20
    = String20 String


create : String -> Maybe String20
create string =
    if String.length string < 20 then
        Just (String20 string)

    else
        Nothing


empty : String20
empty =
    String20 ""


value : String20 -> String
value (String20 string) =
    string


length : String20 -> Int
length (String20 string) =
    String.length string


decoder : Decoder String20
decoder =
    let
        decodeHelper string =
            case create string of
                Nothing ->
                    Decode.fail "too long"

                Just string20 ->
                    Decode.succeed string20
    in
    Decode.string
        |> Decode.andThen decodeHelper


encode : String20 -> Value
encode =
    value >> Encode.string
