module Validated exposing (Validated(..), Validator, combine, compose, max, min, value)


type Validated value
    = Valid value
    | Invalid String value


value : Validated value -> value
value validated =
    case validated of
        Valid val ->
            val

        Invalid _ val ->
            val


type alias Validator value =
    value -> Validated value


min : Int -> Validator String
min n val =
    if String.length val >= n then
        Valid val

    else
        Invalid "too short" val


max : Int -> Validator String
max n val =
    if String.length val <= n then
        Valid val

    else
        Invalid "too long" val


compose : Validator value -> Validator value -> Validator value
compose validator1 validator2 val =
    case validator2 val of
        Valid validVal ->
            validator1 val

        invalid ->
            invalid


combine : List (Validator value) -> Validator value
combine validators =
    List.foldl compose Valid validators
