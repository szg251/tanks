module Data.Bullet exposing
    ( Bullet
    , decoder
    , view
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Svg exposing (..)
import Svg.Attributes exposing (..)


type alias Bullet =
    { x : Int, y : Int }


view : Bullet -> Svg msg
view p =
    circle
        [ cx <| String.fromInt p.x
        , cy <| String.fromInt p.y
        , r "1"
        , fill "black"
        , stroke "black"
        ]
        []


decoder : Decoder Bullet
decoder =
    Decode.succeed Bullet
        |> required "x" Decode.int
        |> required "y" Decode.int
