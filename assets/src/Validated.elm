module Validated exposing
    ( Validated(..)
    , Validator
    , combine
    , compose
    , error
    , invalidate
    , map
    , max
    , min
    , toMaybe
    , value
    )


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


error : Validated value -> String
error validated =
    case validated of
        Valid _ ->
            ""

        Invalid message _ ->
            message


invalidate : String -> Validated value -> Validated value
invalidate message validated =
    Invalid message (value validated)


type alias Validator value =
    value -> Validated value


min : Int -> String -> Validator String
min n message val =
    if String.length val >= n then
        Valid val

    else
        Invalid message val


max : Int -> String -> Validator String
max n message val =
    if String.length val <= n then
        Valid val

    else
        Invalid message val


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


map : (value -> valueB) -> Validated value -> Validated valueB
map func validated =
    case validated of
        Valid val ->
            Valid (func val)

        Invalid message val ->
            Invalid message (func val)


toMaybe : Validated value -> Maybe value
toMaybe validated =
    case validated of
        Valid val ->
            Just val

        Invalid _ _ ->
            Nothing
