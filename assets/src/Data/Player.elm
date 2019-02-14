module Data.Player exposing (Authenticated(..), Player, decoder, encode)

import Data.String20 as String20 exposing (String20)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode exposing (Value)


type alias Player =
    { name : String20 }


type Authenticated entity
    = NotAsked
    | NoPlayer
    | Authenticated entity


decoder : Decoder Player
decoder =
    Decode.succeed Player
        |> required "name" String20.decoder


encode : Player -> Value
encode player =
    Encode.object [ ( "name", String20.encode player.name ) ]
